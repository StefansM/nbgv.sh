# nbgv.sh

This script provides semver-compatible versioning for any project in a git
repository, inspired by [Nerdbank.GitVersioning].

[Nerdbank.GitVersioning]: https://github.com/dotnet/Nerdbank.GitVersioning

## Usage

Nbgv.sh is a single, POSIX-compatible script. Add a `version.txt` file
containing a base version to the root of your git repositry, and nbgv.sh will
automatically bump the patch version number for each commit since `version.txt`
was last changed. To bump major or minor versions, manually bump the version in
`version.txt`.

First, initialise your project with a base version. After `version.txt` has
been committed, nbgv.sh will return the version number in `version.txt`.

```console
$ git init
$ echo 0.1.0 > version.txt
$ git add version.txt
$ git commit -m 'Begin versioning with nbgv.sh'
$ nbgv.sh
0.1.0
```

Next, add some commits. The version number returned by nbgv.sh will increment
with each commit.

```console
$ git commit --allow-empty -m 'Empty commit 1'
$ git commit --allow-empty -m 'Empty commit 2'
$ nbgv.sh
0.1.2
```

To cut a new minor version, simply bump `version.txt` manually:

```console
$ echo 0.2.0 > version.txt
$ git add version.txt
$ git commit -m 'Bump minor version'
$ nbgv.sh
0.2.0
```

When working on a non-default branch, nbgv.sh will add a `-dev` suffix:

```console
$ git checkout -b feature
$ git commit --allow-empty -m 'Empty commit on feature branch'
$ nbgv.sh
0.2.1-dev
```

## Monorepos

If your repository is a monorepo, set the environment variable `MONOREPO`. In
this mode, nbgv.sh will search upwards from the current directory, up to the
root of the repository, and use the first 'version.txt' file that it finds.

For example:

```console
$ mkdir project1 project2
$ echo 1.0.0 > project1/version.txt
$ echo 0.1.0 > project2/version.txt
$ git add project1 project2
$ git commit -m 'Initial commit'
$ cd project1
$ MONOREPO=1 nbgv.sh
0.1.0
$ cd ../project2
$ MONOREPO=1 nbgv.sh
1.0.0
```


## Installation

To install nbgv.sh, download the script and add it to your `$PATH`:

```console
$ curl -O https://raw.githubusercontent.com/StefansM/nbgv.sh/main/nbgv.sh
$ sudo mv nbgv.sh /usr/local/bin
```

## Configuration

Nbgv.sh is intentionally simple, but it does support a couple of options. To
enable each option, set the corresponding environment variable:

* Verbose mode (`V`): Print some debugging information to standard error.
  `V=1 nbgv.sh`.

* Main branch (`MAIN_BRANCH`): Set this to the name of your main branch if it's
  not `main` or `master`: `MAIN_BRANCH=my-main-branch nbgv.sh`.
