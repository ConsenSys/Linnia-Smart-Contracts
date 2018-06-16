Contributing to Linnia-Smart-Contracts
=======

We really appreciate and value contributions to Linnia-Smart-Contracts. Please take 5' to review the items listed below to make sure that your contributions are merged as soon as possible. 

## Contribution guidelines

Smart contracts manage value and are highly vulnerable to errors and attacks. Please review the Ethereum Smart Contract Security Best Practices:
(https://consensys.github.io/smart-contract-best-practices/).

## Creating Pull Requests (PRs)

As a contributor, you are expected to fork this repository, work on your own fork and then submit pull requests. The pull requests will be reviewed and eventually merged into the main repo. See ["Fork-a-Repo"](https://help.github.com/articles/fork-a-repo/) for how this works.

## A typical workflow

1) Make sure your fork is up to date with the main repository:

```
cd Linnia-Smart-Contracts
git remote add upstream https://github.com/Linnia-Smart-Contracts/Linnia-Smart-Contracts.git
git fetch upstream
git pull --rebase upstream master
```
NOTE: The directory `Linnia-Smart-Contracts` represents your fork's local copy.

2) Branch out from `master` into `fix/some-bug-#123`:
(Postfixing #123 will associate your PR with the issue #123 and make everyone's life easier =D)
```
git checkout -b fix/some-bug-#123
```

3) Make your changes, add your files, commit and push to your fork.

```
git add SomeFile.js
git commit "Fix some bug #123"
git push origin fix/some-bug-#123
```

4) Go to [github.com/Consensys/Linnia-Smart-Contracts](https://github.com/Consensys/Linnia-Smart-Contracts) in your web browser and issue a new pull request.

*IMPORTANT* Please ensure the PR is of your highest quality code. Please verify the PR by making sure that all tests pass, JS linting tests pass, solidity linting tests pass, etc.

5) Maintainers will review your code and possibly ask for changes before your code is pulled in to the main repository. We'll check that all tests pass, review the coding style, and check for general code correctness. If everything is OK, we'll merge your pull request and your code will be part of Linnia-Smart-Contracts.

*IMPORTANT* Please pay attention to the maintainer's feedback, since its a necessary step to keep up with the standards Linnia-Smart-Contracts attains to.

## All set!

If you have any questions feel free to post them to github.com/Consensys/Linnia-Smart-Contracts/issues.

Finally, if you're looking to collaborate and want to find easy tasks to start, look at the issues we marked as ["Good first issue"](https://github.com/Consensys/Linnia-Smart-Contracts/labels/good%20first%20issue).

Thanks for your time and code!