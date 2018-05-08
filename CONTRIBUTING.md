# Contributing to smart-mastering-core

Smart-mastering-core welcomes new contributors. This document will guide you
through the process.

 - [Question or Problem?](#question)
 - [Issues and Bugs](#issue)
 - [Feature Requests](#feature)
 - [Submission Guidelines](#submit)
 
## <a name="question"></a> Got a Question or Problem?

If you need help working with smart-mastering-core, please ask it on [Stack
Overflow with the "marklogic" tag][stackoverflow]. 

## <a name="issue"></a> Found an Issue?
If you find a bug in the source code or a mistake in the documentation, you 
can help us by submitting an issue to our [GitHub Issue Tracker][issue tracker]. 
Even better you can submit a Pull Request with a fix for the issue you filed.

## <a name="feature"></a> Want a Feature?
You can request a new feature by submitting an issue to our [GitHub Issue 
Tracker][issue tracker].  If you would like to implement a new feature then 
first create a new issue and discuss it with one of our project maintainers.

## <a name="submit"></a> Submission Guidelines

### Submitting an Issue
Before you submit your issue search the current issues to see whether your 
question or request has been addressed. 

If your issue appears to be a bug, and hasn't been reported, open a new issue.
Providing the following information will increase the chances of your issue 
being dealt with quickly:

* **Overview of the Issue** - if an error is being thrown a stack trace helps
* **Motivation for or Use Case** - explain why this is a bug for you
* **smart-mastering-core Version** - is it a named version or from our dev branch
* **MarkLogic Version** - the version of MarkLogic you're working with
* **Operating System** - Mac, windows? details help
* **Suggest a Fix** - if you can't fix the bug yourself, perhaps you can point to what might be
  causing the problem (line of code or commit)

### Submitting a Pull Request

#### Fork smart-mastering-core

Fork the project [on GitHub](https://github.com/marklogic-community/smart-mastering-core/fork) 
and clone
your copy.

```sh
$ git clone git@github.com:username/smart-mastering-core.git
$ cd smart-mastering-core
$ git remote add upstream git://github.com/marklogic-community/smart-mastering-core.git
```

All bug fixes and new features currently go into the master branch. This will 
change when we're a little further along. 

We ask that you open an issue in the [issue tracker][] and get agreement from
at least one of the project maintainers before you start coding.

Nothing is more frustrating than seeing your hard work go to waste because
your vision does not align with that of a project maintainer.


#### Create a branch for your changes

Okay, so you have decided to fix something. Create a feature branch
and start hacking:

```sh
$ git checkout -b my-feature-branch -t origin/master
```

#### Formatting code

We use [.editorconfig][] to configure our editors for proper code formatting. If you don't
use a tool that supports editorconfig be sure to configure your editor to use the settings
equivalent to our .editorconfig file.

#### Commit your changes

Make sure git knows your name and email address:

```sh
$ git config --global user.name "J. Random User"
$ git config --global user.email "j.random.user@example.com"
```

Writing good commit logs is important. A commit log should describe what
changed and why. Follow these guidelines when writing one:

1. The first line should be 50 characters or less and contain a short
   description of the change including the Issue number prefixed by a hash (#).
2. Keep the second line blank.
3. Wrap all other lines at 72 columns.

A good commit log looks like this:

```
Fixing Issue #123: make the whatchamajigger work in MarkLogic 8

Body of commit message is a few lines of text, explaining things
in more detail, possibly giving some background about the issue
being fixed, etc etc.

The body of the commit message can be several paragraphs, and
please do proper word-wrap and keep columns shorter than about
72 characters or so. That way `git log` will show things
nicely even when it is indented.
```

The header line should be meaningful; it is what other people see when they
run `git shortlog` or `git log --oneline`.

#### Rebase your repo

Use `git rebase` (not `git merge`) to sync your work from time to time.

```sh
$ git fetch upstream
$ git rebase upstream/master
```


#### Test your code

We are working hard to improve smart-mastering-core's testing. If you add new 
functions in XQuery or JavaScript code then please write unit tests in the 
[suites directory](https://github.com/marklogic-community/smart-mastering-core/tree/master/src/test/ml-modules/root/test/suites).

To deploy the code, including the tests, use this command:

```sh
$ gradle mlDeploy
```

When finished, verify that the self-test works. Make sure that all tests pass. 
Please, do not submit patches that fail.

##### Using Gradle

```sh
$ gradle mlUnitTest
```

##### Using the Test UI

Assuming the default configuration, point a browser to the [test UI][test ui]. 

#### Push your changes

```sh
$ git push origin my-feature-branch
```

#### Agree to the contributor License
Before we can merge your changes, you need to sign a [Contributor License 
Agreement][cla]. You only need to do this once.

#### Submit the pull request

Go to https://github.com/username/smart-mastering-core and select your feature 
branch. Click the 'Pull Request' button and fill out the form.

Pull requests are usually reviewed within a few days. If you get comments
that need to be to addressed, apply your changes in a separate commit and push 
that to your feature branch. Post a comment in the pull request afterwards; 
GitHub does not send out notifications when you add commits to existing pull 
requests.

That's it! Thank you for your contribution!

#### After your pull request is merged

After your pull request is merged, you can safely delete your branch and pull the changes
from the main (upstream) repository:

* Delete the remote branch on GitHub either through the GitHub web UI or your local shell as follows:

    ```shell
    git push origin --delete my-feature-branch
    ```

* Check out the master branch:

    ```shell
    git checkout master -f
    ```

* Delete the local branch:

    ```shell
    git branch -D my-feature-branch
    ```

* Update your master with the latest upstream version:

    ```shell
    git pull --ff upstream master
    ```

[issue tracker]: https://github.com/marklogic-community/smart-mastering-core/issues
[.editorconfig]: http://editorconfig.org/
[stackoverflow]: http://stackoverflow.com/questions/ask?tags=marklogic
[test ui]: http://localhost:8042/test
[cla]: http://developer.marklogic.com/products/cla
