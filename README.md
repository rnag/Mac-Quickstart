# Mac-Quickstart

A collection of scripts and commands useful for "quick-start" setup of a brand-new Macbook Laptop (Apple Silicon preferred)

## Bootstrap SSH for GitHub

> **_Why?_** Suppose you have 2 GitHub accounts. One for _personal_, another for _work_. The **best** (and **only**) approach for this scenario is setting up SSH with `git`.

Start out by downloading the `bootstrap_ssh_for_github.sh` shell script
to [set up SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) (and GPG for [commit verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)) on GitHub:

```sh
curl -fsSL https://raw.githubusercontent.com/rnag/Mac-Quickstart/main/scripts/bootstrap_ssh_for_github.sh -o bootstrap_ssh_for_github.sh
```

Then, open the shell script in a text editor.

```sh
open -e bootstrap_ssh_for_github.sh
```

Replace the following values with your actual GitHub account info:

```
    'Personal|user1|user1@example.com'
    'Work|user2|user2@example.com'
```

Then, run the script:

```sh
/bin/bash bootstrap_ssh_for_github.sh
```

Watch for user input.

**Notes**:

-   This is a guided script.
-   Passwords will be masked.
-   Public and private keys will be temporarily copied to your clipboard, to aid in the setup process.

### Common Issues

After running script, you still receive
a `403` error upon `git push`.

```console
$ git push
remote: Permission to <user>/<repo>.git denied to <your-user>.
fatal: unable to access 'https://github.com/<user>/<repo>/': The requested URL returned error: 403
```

**Cause**: You might be currently set up to use HTTPS (instead of SSH) for `git`.

**Solution**: Add the following lines to your `~/.gitconfig` file.

```ini
[url "git@github.com:"]
	insteadOf = https://github.com/
[url "git://"]
	insteadOf = https://
```

Now, try that again:

```sh
git push
```

## Feedback

Let me know if there are any issues or feedback.

Feel free to reach out [via email](mailto:me@ritviknag.com).

You can also [open an issue](https://github.com/rnag/Mac-Quickstart/issues) if there is a feature or suggestion you'd like to see. Contributions are welcome.
