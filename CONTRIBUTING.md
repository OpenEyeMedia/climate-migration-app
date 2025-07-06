# Contributing to Climate Adaptation App

Thank you for your interest in contributing to the Climate Adaptation App! This document provides guidelines for contributing to the project.

## Code of Conduct

Please read and follow our Code of Conduct to help maintain a welcoming environment for all contributors.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in the [Issues](https://github.com/yourorg/climate-adaptation-app/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Environment details

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue with the `enhancement` label
3. Describe the feature and its benefits
4. Include mockups or examples if possible

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Follow the coding standards (see below)
4. Write tests for new functionality
5. Ensure all tests pass
6. Commit with clear messages following conventional commits
7. Push to your fork and submit a pull request

## Development Setup

See the [README](README.md) for detailed setup instructions.

## Coding Standards

### Python
- Follow PEP 8
- Use type hints
- Write docstrings for all public functions
- Format with Black

### TypeScript/JavaScript
- Use TypeScript strict mode
- Follow ESLint rules
- Format with Prettier
- Write JSDoc comments

### Git Commits
Follow conventional commits format:
```
type(scope): subject

body (optional)

footer (optional)
```

Types: feat, fix, docs, style, refactor, test, chore

## Testing

- Write unit tests for new functions
- Ensure 80%+ code coverage
- Run tests before submitting PR: `npm test` and `pytest`

## Questions?

Feel free to ask in the issues or discussions section!
