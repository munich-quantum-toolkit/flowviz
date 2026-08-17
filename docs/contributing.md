# Contributing

Thank you for your interest in contributing to MQT FlowViz! This document
outlines the development guidelines and how to contribute.

We use GitHub to
[host code](https://github.com/munich-quantum-toolkit/flowviz), to
[track issues and feature requests][issues], as well as accept
[pull requests](https://github.com/munich-quantum-toolkit/flowviz/pulls). See
<https://docs.github.com/en/get-started/quickstart> for a general introduction
to working with GitHub and contributing to projects.

## Types of Contributions

Pick the path that fits your time and interests:

- 🐛 Report bugs using the _🐛 Bug report_ template. Include steps to reproduce,
  expected and actual behavior, your environment, and a minimal example.
- 🛠️ Fix bugs listed in [issues][issues]. Open a draft PR early to get feedback.
- 💡 Propose features using the _✨ Feature request_ template. Describe the
  motivation and alternatives considered.
- ✨ Implement features. Coordinate in the issue first if the change is
  substantial.
- 📝 Improve documentation, examples, and explanations.
- 🙌 Help other users in
  [Discussions](https://github.com/munich-quantum-toolkit/flowviz/discussions).

## Guidelines

- Write meaningful commit messages, preferably using
  [gitmoji](https://gitmoji.dev) for additional context.
- Focus on a single feature or bug at a time and only touch relevant files.
- Add tests for new features and bug fixes where applicable.
- Document new features and keep the code readable.
- Remove debug statements, leftover comments, and unrelated code.
- Run the formatting and linting checks before committing.
- Be open to feedback and willing to make changes during review.

Please read and follow the project's [AI usage guidelines](ai_usage.md) for any
AI-assisted contribution. In particular, contributors remain responsible for
every submitted line and must disclose material AI assistance in the PR
description.

## Pull Request Workflow

- Create PRs early and mark work in progress as draft.
- Use a clear title, reference related issues, and follow the PR template.
- Keep the PR focused and make sure the app builds before requesting review.
- Address review feedback on the same branch and re-request review afterward.

## Development Setup

Follow the [installation guide](installation.md) to prepare Xcode and run the
app. Before committing, run all repository checks from the project root:

```console
uvx prek run -a
```

The Swift formatter uses the repository's Google-style configuration in
`.swift-format`.

[issues]: https://github.com/munich-quantum-toolkit/flowviz/issues
