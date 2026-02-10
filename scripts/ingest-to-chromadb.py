#!/usr/bin/env python3
"""
ChromaDB Ingestion Pipeline for Claude Code Shared Memory System

This script ingests CLAUDE.md, MEMORY.md, Obsidian vault, and Docker configs
into ChromaDB collections for semantic search. Supports incremental updates
and idempotent upserts based on file content hashes.

Usage:
    python ingest-to-chromadb.py [--full] [--dry-run] [--verbose]

Collections:
    - infrastructure: IPs, services, ports, Docker stacks, network topology
    - decisions: Architecture choices, security hardening, troubleshooting
    - documentation: Project docs, service pages, reference material

Author: Claude Code + James Hathcock
Last Modified: 2026-02-09
"""

import os
import sys
import hashlib
import logging
import argparse
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass

import chromadb
from chromadb.utils import embedding_functions
import frontmatter
from dotenv import load_dotenv


# ============================================================================
# Configuration
# ============================================================================

@dataclass
class SourceConfig:
    """Configuration for a single source directory or file"""
    path: Path
    collection: str  # infrastructure, decisions, or documentation
    source_type: str  # claude-md, obsidian, docker-config
    domain: Optional[str] = None  # e.g., "networking", "security", "media"
    patterns: List[str] = None  # glob patterns to match

    def __post_init__(self):
        if self.patterns is None:
            self.patterns = ["*.md"]


# Source definitions (adapt paths based on environment)
def get_source_configs(base_dirs: Dict[str, Path]) -> List[SourceConfig]:
    """Generate source configurations from base directories"""
    configs = []

    claude_config = base_dirs.get('claude_config')
    obsidian = base_dirs.get('obsidian')
    homelab_ops = base_dirs.get('homelab_ops')

    # Session MEMORY.md → decisions collection
    if claude_config and (claude_config / "session/MEMORY.md").exists():
        configs.append(SourceConfig(
            path=claude_config / "session/MEMORY.md",
            collection="decisions",
            source_type="claude-md",
            domain="session-memory"
        ))

    # Project CLAUDE.md files → mixed collections based on content
    if claude_config:
        for project_dir in (claude_config / "projects").glob("*"):
            if project_dir.is_dir():
                claude_md = project_dir / "CLAUDE.md"
                if claude_md.exists():
                    # homelab-ops goes to infrastructure, others to documentation
                    collection = "infrastructure" if project_dir.name == "homelab-ops" else "documentation"
                    configs.append(SourceConfig(
                        path=claude_md,
                        collection=collection,
                        source_type="claude-md",
                        domain=project_dir.name
                    ))

    # Obsidian vault → process ALL subdirectories
    if obsidian and obsidian.exists():
        # Get all subdirectories in the vault
        for subdir in obsidian.glob("*"):
            if subdir.is_dir() and not subdir.name.startswith('.'):
                # Map directories to collections based on name
                if subdir.name.lower() in ['infrastructure']:
                    collection = "infrastructure"
                elif subdir.name.lower() in ['security', 'changelog']:
                    collection = "decisions"
                else:
                    # Everything else goes to documentation
                    collection = "documentation"

                configs.append(SourceConfig(
                    path=subdir,
                    collection=collection,
                    source_type="obsidian",
                    domain=subdir.name.lower()
                ))

        # Also process top-level markdown files in the vault
        for md_file in obsidian.glob("*.md"):
            if md_file.is_file():
                configs.append(SourceConfig(
                    path=md_file,
                    collection="documentation",
                    source_type="obsidian",
                    domain="vault-root"
                ))

    # Docker Compose files → infrastructure collection
    if homelab_ops and (homelab_ops / "docker-compose.yml").exists():
        configs.append(SourceConfig(
            path=homelab_ops / "docker-compose.yml",
            collection="infrastructure",
            source_type="docker-config",
            domain="docker-compose",
            patterns=["docker-compose.yml"]
        ))

    # Additional Documents directory markdown files
    docs_dir = Path("/home/cib/Documents")
    if docs_dir.exists():
        # Process top-level markdown files in Documents
        for md_file in docs_dir.glob("*.md"):
            if md_file.is_file() and not md_file.name.startswith('_'):
                # Determine collection based on filename
                filename_lower = md_file.stem.lower()
                if 'stronghold' in filename_lower or 'deployment' in filename_lower:
                    collection = "infrastructure"
                elif 'chromadb' in filename_lower:
                    collection = "decisions"
                else:
                    collection = "documentation"

                configs.append(SourceConfig(
                    path=md_file,
                    collection=collection,
                    source_type="documentation",
                    domain="documents-root"
                ))

        # Process Build Outs and other subdirectories
        for subdir in ["Build Outs", "Python and Markdown"]:
            subdir_path = docs_dir / subdir
            if subdir_path.exists() and subdir_path.is_dir():
                configs.append(SourceConfig(
                    path=subdir_path,
                    collection="documentation",
                    source_type="documentation",
                    domain=subdir.lower().replace(' ', '-')
                ))

    return configs


# ============================================================================
# Document Processing
# ============================================================================

def chunk_by_headings(content: str, file_path: Path, max_tokens: int = 800) -> List[Tuple[str, Dict]]:
    """
    Split markdown content by heading boundaries.

    Returns list of (chunk_text, metadata) tuples.
    Each chunk includes the heading and content until the next heading.
    Rough token estimation: 1 token ≈ 4 characters.
    """
    lines = content.split('\n')
    chunks = []
    current_chunk = []
    current_heading = None
    current_size = 0

    for line in lines:
        # Detect markdown headings (# through ####)
        if line.startswith('#') and not line.startswith('#####'):
            # If we have accumulated content, save it as a chunk
            if current_chunk:
                chunk_text = '\n'.join(current_chunk).strip()
                if chunk_text:  # Skip empty chunks
                    chunks.append((chunk_text, {'heading': current_heading}))

            # Start new chunk with this heading
            current_heading = line.strip('#').strip()
            current_chunk = [line]
            current_size = len(line)
        else:
            # Add line to current chunk
            current_chunk.append(line)
            current_size += len(line)

            # If chunk exceeds max size, split here
            if current_size > max_tokens * 4:  # rough char-to-token conversion
                chunk_text = '\n'.join(current_chunk).strip()
                if chunk_text:
                    chunks.append((chunk_text, {'heading': current_heading}))
                current_chunk = []
                current_size = 0

    # Save final chunk
    if current_chunk:
        chunk_text = '\n'.join(current_chunk).strip()
        if chunk_text:
            chunks.append((chunk_text, {'heading': current_heading}))

    # If no chunks created (no headings), treat whole file as one chunk
    if not chunks and content.strip():
        chunks.append((content.strip(), {'heading': file_path.stem}))

    return chunks


def compute_file_hash(file_path: Path) -> str:
    """Compute SHA256 hash of file contents"""
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()[:16]  # Use first 16 chars for brevity


def process_file(
    file_path: Path,
    source_config: SourceConfig,
    state_tracker: Dict[str, any]
) -> List[Dict]:
    """
    Process a single file into ChromaDB document format.

    Returns list of document dicts with keys: id, content, metadata
    """
    # Check if file changed since last ingestion (incremental updates)
    file_stat = file_path.stat()
    last_modified = datetime.fromtimestamp(file_stat.st_mtime).isoformat()

    if not state_tracker.get('full_refresh', False):
        last_ingested = state_tracker.get('file_mtimes', {}).get(str(file_path))
        if last_ingested and last_ingested >= last_modified:
            logging.debug(f"Skipping unchanged file: {file_path}")
            return []

    # Read file content
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            raw_content = f.read()
    except Exception as e:
        logging.error(f"Failed to read {file_path}: {e}")
        return []

    # Parse frontmatter if present (Obsidian files)
    if source_config.source_type == "obsidian":
        try:
            post = frontmatter.loads(raw_content)
            content = post.content
            frontmatter_meta = post.metadata
        except:
            content = raw_content
            frontmatter_meta = {}
    else:
        content = raw_content
        frontmatter_meta = {}

    # Chunk content by headings
    chunks = chunk_by_headings(content, file_path)

    # Generate document hashes for idempotent IDs
    file_hash = compute_file_hash(file_path)

    documents = []
    for idx, (chunk_text, chunk_meta) in enumerate(chunks):
        # Generate stable document ID: file_hash + chunk_index
        doc_id = f"{file_hash}_{idx}"

        # Build comprehensive metadata
        metadata = {
            'source_file': str(file_path),
            'source_type': source_config.source_type,
            'collection': source_config.collection,
            'domain': source_config.domain or file_path.parent.name,
            'last_modified': last_modified,
            'chunk_index': idx,
            'total_chunks': len(chunks),
        }

        # Add heading info if available
        if chunk_meta.get('heading'):
            metadata['heading'] = chunk_meta['heading']

        # Add Obsidian frontmatter metadata
        if frontmatter_meta:
            for key, value in frontmatter_meta.items():
                if isinstance(value, (str, int, float, bool)):
                    metadata[f"fm_{key}"] = str(value)

        documents.append({
            'id': doc_id,
            'content': chunk_text,
            'metadata': metadata
        })

    # Update state tracker
    state_tracker.setdefault('file_mtimes', {})[str(file_path)] = last_modified
    state_tracker.setdefault('processed_files', []).append(str(file_path))

    logging.info(f"Processed {file_path.name}: {len(chunks)} chunks")
    return documents


# ============================================================================
# ChromaDB Operations
# ============================================================================

def init_chromadb_client(host: str, port: int, token: str) -> chromadb.HttpClient:
    """Initialize ChromaDB HTTP client with authentication"""
    # ChromaDB 1.0.0+ uses simple header-based authentication
    client = chromadb.HttpClient(
        host=host,
        port=port,
        headers={"Authorization": f"Bearer {token}"}
    )

    # Test connection
    client.heartbeat()
    logging.info(f"Connected to ChromaDB at {host}:{port}")

    return client


def ensure_collections(client: chromadb.HttpClient) -> Dict[str, chromadb.Collection]:
    """Ensure all required collections exist with default embedding function"""
    # Use ChromaDB's default embedding function (all-MiniLM-L6-v2)
    # Runs inside the container, no external dependencies
    default_ef = embedding_functions.DefaultEmbeddingFunction()

    collections = {}
    for name in ['infrastructure', 'decisions', 'documentation']:
        try:
            # Get existing collection or create new one
            collection = client.get_or_create_collection(
                name=name,
                embedding_function=default_ef,
                metadata={"description": f"Claude Code shared memory: {name}"}
            )
            collections[name] = collection
            logging.info(f"Collection '{name}' ready (count: {collection.count()})")
        except Exception as e:
            logging.error(f"Failed to initialize collection '{name}': {e}")
            raise

    return collections


def upsert_documents(
    collections: Dict[str, chromadb.Collection],
    documents: List[Dict],
    dry_run: bool = False
) -> Tuple[int, int]:
    """
    Upsert documents into appropriate collections.

    Returns (added_count, updated_count) tuple.
    Uses document IDs for idempotent upserts.
    """
    if dry_run:
        logging.info(f"[DRY RUN] Would upsert {len(documents)} documents")
        return (len(documents), 0)

    # Group documents by collection
    docs_by_collection = {}
    for doc in documents:
        collection_name = doc['metadata']['collection']
        docs_by_collection.setdefault(collection_name, []).append(doc)

    added = 0
    updated = 0

    for collection_name, docs in docs_by_collection.items():
        collection = collections[collection_name]

        # Prepare batch data
        ids = [doc['id'] for doc in docs]
        contents = [doc['content'] for doc in docs]
        metadatas = [doc['metadata'] for doc in docs]

        try:
            # Check which IDs already exist
            existing = collection.get(ids=ids, include=[])
            existing_ids = set(existing['ids']) if existing['ids'] else set()

            # Upsert all documents (ChromaDB handles insert vs update)
            collection.upsert(
                ids=ids,
                documents=contents,
                metadatas=metadatas
            )

            # Track stats
            new_docs = len(ids) - len(existing_ids)
            updated_docs = len(existing_ids)

            added += new_docs
            updated += updated_docs

            logging.info(
                f"Collection '{collection_name}': "
                f"+{new_docs} new, ~{updated_docs} updated"
            )

        except Exception as e:
            logging.error(f"Failed to upsert to '{collection_name}': {e}")
            raise

    return (added, updated)


# ============================================================================
# State Management
# ============================================================================

def load_state(state_file: Path) -> Dict:
    """Load ingestion state from JSON file"""
    if state_file.exists():
        import json
        try:
            with open(state_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            logging.warning(f"Failed to load state file: {e}")
    return {'file_mtimes': {}, 'last_run': None}


def save_state(state_file: Path, state: Dict):
    """Save ingestion state to JSON file"""
    import json
    state['last_run'] = datetime.now().isoformat()
    try:
        with open(state_file, 'w') as f:
            json.dump(state, indent=2, fp=f)
        logging.debug(f"State saved to {state_file}")
    except Exception as e:
        logging.error(f"Failed to save state: {e}")


# ============================================================================
# Main Pipeline
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Ingest documentation into ChromaDB for Claude Code shared memory"
    )
    parser.add_argument(
        '--full',
        action='store_true',
        help="Force full refresh (ignore incremental state)"
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help="Show what would be ingested without writing to ChromaDB"
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help="Enable verbose debug logging"
    )
    args = parser.parse_args()

    # Setup logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s [%(levelname)s] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Load environment variables
    script_dir = Path(__file__).parent
    env_file = script_dir / '.env'
    if not env_file.exists():
        logging.error(
            f"Missing .env file at {env_file}\n"
            "Copy .env.example and fill in your ChromaDB credentials."
        )
        return 1

    load_dotenv(env_file)

    # Get configuration from environment
    chromadb_host = os.getenv('CHROMADB_HOST', '192.168.1.60')
    chromadb_port = int(os.getenv('CHROMADB_PORT', '8000'))
    chromadb_token = os.getenv('CHROMADB_AUTH_TOKEN')

    if not chromadb_token:
        logging.error("CHROMADB_AUTH_TOKEN not set in .env file")
        return 1

    # Base directories
    base_dirs = {
        'claude_config': Path(os.getenv('CLAUDE_CONFIG_DIR', '/home/cib/ai-assistant-config')),
        'obsidian': Path(os.getenv('OBSIDIAN_VAULT_DIR', '/home/cib/Documents/homelab-docs')),
        'homelab_ops': Path(os.getenv('HOMELAB_OPS_DIR', '/home/cib/homelab-ops')),
    }

    # State tracking
    state_file = script_dir / '.ingest-state.json'
    state = load_state(state_file)
    if args.full:
        state['full_refresh'] = True
        logging.info("Running full refresh (ignoring incremental state)")

    try:
        # Initialize ChromaDB connection
        logging.info(f"Connecting to ChromaDB at {chromadb_host}:{chromadb_port}...")
        client = init_chromadb_client(chromadb_host, chromadb_port, chromadb_token)
        collections = ensure_collections(client)

        # Get source configurations
        source_configs = get_source_configs(base_dirs)
        logging.info(f"Found {len(source_configs)} source configurations")

        # Process all sources
        all_documents = []
        for config in source_configs:
            if config.path.is_file():
                # Single file source
                docs = process_file(config.path, config, state)
                all_documents.extend(docs)
            elif config.path.is_dir():
                # Directory source - process all matching files
                for pattern in config.patterns:
                    for file_path in config.path.rglob(pattern):
                        if file_path.is_file():
                            docs = process_file(file_path, config, state)
                            all_documents.extend(docs)
            else:
                logging.warning(f"Source path does not exist: {config.path}")

        # Upsert to ChromaDB
        if all_documents:
            added, updated = upsert_documents(collections, all_documents, args.dry_run)
            logging.info(f"✓ Ingestion complete: {added} added, {updated} updated")

            # Save state
            if not args.dry_run:
                save_state(state_file, state)
        else:
            logging.info("No changes detected (all files up to date)")

        return 0

    except Exception as e:
        logging.error(f"Ingestion failed: {e}", exc_info=args.verbose)
        return 1


if __name__ == '__main__':
    sys.exit(main())
