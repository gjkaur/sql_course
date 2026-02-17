# Contributing to SQL Mastery Course

Thank you for your interest in contributing! This document provides guidelines for contributing to the course.

## How to Contribute

### Reporting Issues

- Use the GitHub issue tracker for bugs, typos, or unclear explanations
- Include the module number and file path when reporting
- For SQL errors, include the full error message and PostgreSQL version

### Suggesting Improvements

- Open an issue with the `enhancement` label
- Describe the improvement and why it would help learners
- For new exercises, include the expected solution approach

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Follow existing code style and folder structure
4. Add or update tests if applicable
5. Update documentation if needed
6. Submit a PR with a clear description

### Code Style

- **SQL**: Use lowercase for keywords, 2-space indentation
- **Markdown**: Use ATX-style headers (`#`, `##`), wrap at 100 chars
- **Comments**: Explain *why* in SQL, not *what*

### Module Structure

Each module should include:

- `README.md` - Overview and learning objectives
- `theory/` - Engineer-focused summaries
- `labs/` or `project/` - Hands-on exercises
- `interview_questions.md` - Interview-style Q&A

### Testing

- SQL scripts should run without errors on PostgreSQL 15+
- Use `\i` or `psql -f` to verify scripts execute correctly
