# Contributing to Disenchanter

## Translations

You can contribute translations for your language using the translation platform [Weblate](https://weblate.ms-ds.org/engage/disenchanter/).

**Steps:**
- Register by email or using GitHub SSO
- Choose an [existing translation](https://weblate.ms-ds.org/projects/disenchanter/disenchanter/) or [start a new translation](https://weblate.ms-ds.org/new-lang/disenchanter/disenchanter/)
- You will be presented with the English source text and can enter your language's translation
- To prevent abuse, your translations will be saved as suggestions that will regularly be accepted and merged by project maintainers.
- Make sure to place interpolated variables where appropriate
  - They look like this: `My name is %{name}`, so you'd translate like this: `Ich heiße %{name}`

### Translation status

[![](https://weblate.ms-ds.org/widget/disenchanter/disenchanter/multi-auto.svg)](https://weblate.ms-ds.org/engage/disenchanter/)

## Code

### Bug Report

- Make sure the problem hasn't already been reported under [Issues](https://github.com/marvinscham/disenchanter/issues).
  - Add a reaction or provide additional details if you encounter a problem that has already been reported.
- If there's no open issue with addressing your problem, [open a new one](https://github.com/marvinscham/disenchanter/issues/new?assignees=marvinscham&labels=bug&projects=&template=bug_report.md&title=).
  - Please refer to the provided issue structure to help keeping things structured.

### Pull Requests

#### Bug Fixes

- Wrote a patch for the bug you found?
  - Open a pull request and provide a clear description of the problem and your solution.
  - Include relevant issue numbers if applicable.
  - Pure whitespace, formatting or cosmetic changes will not be accepted.

#### New Features

- Please [create an issue](https://github.com/marvinscham/disenchanter/issues/new?assignees=marvinscham&labels=enhancement&projects=&template=feature_request.md&title=) with your feature idea so we can talk about it before you start coding.
  - This way we make sure nobody wastes their time.
  - Make sure not to introduce new RuboCop problems.
- Otherwise, same as bug fixes