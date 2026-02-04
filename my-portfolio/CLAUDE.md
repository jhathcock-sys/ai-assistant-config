# CLAUDE.md - Portfolio Site

<project>
    <overview>
        Personal portfolio and resume site built with Hugo static site generator.
        Hosted on GitHub Pages with automatic deployment on push.
    </overview>

    <tech_stack>
        <framework>Hugo</framework>
        <theme>PaperMod (git submodule)</theme>
        <hosting>GitHub Pages</hosting>
        <domain>https://jhathcock-sys.github.io/me/</domain>
    </tech_stack>

    <structure>
        <file path="content/resume.md">Resume page with TOC</file>
        <file path="content/projects/_index.md">Projects listing page</file>
        <file path="content/projects/home-lab.md">HomeLab project writeup</file>
        <file path="content/projects/GitOps.md">GitOps project writeup</file>
        <file path="content/projects/claude-memory.md">Claude Memory System writeup</file>
        <file path="hugo.yaml">Site configuration</file>
        <file path="static/files/">PDF resume, downloadable files</file>
        <file path="static/images/">Profile photo, favicon</file>
        <file path="themes/PaperMod/">Theme (git submodule)</file>
    </structure>

    <commands>
        <cmd name="dev">hugo server -D</cmd>
        <cmd name="build">hugo</cmd>
        <cmd name="deploy">git push (auto via GitHub Actions)</cmd>
    </commands>

    <content_tips>
        <tip>Frontmatter required: title, date, draft</tip>
        <tip>URL structure: site is at /me/ subdirectory</tip>
        <tip>Use relative links between projects (../gitops/ not /projects/gitops/)</tip>
        <tip>Config URLs need full path (/me/resume/)</tip>
        <tip>Projects link to each other for navigation</tip>
    </content_tips>

    <features>
        <feature>Homepage hero card with social links</feature>
        <feature>Resume page with PDF download</feature>
        <feature>Project writeups with code highlighting</feature>
        <feature>Dark/Light mode (follows system)</feature>
        <feature>SEO metadata configured</feature>
    </features>

    <new_project_template>
        <step>Create content/projects/new-project.md</step>
        <frontmatter>
            title: "Project Name"
            date: 2026-02-02
            draft: false
        </frontmatter>
        <step>Write content in markdown</step>
        <step>Link from other projects using relative paths</step>
    </new_project_template>
</project>
