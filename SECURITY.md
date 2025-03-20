# Security policy

The release model of the core20 snap is following rolling releases. 

The snap is released into the edge channel, where edge validation is performed. If the validation 
succeeds, it is automatically promoted to the beta channel if a snap revision is not already in progress 
for beta validation. When in beta-validation the snap is then tested on various real hardware. If the beta
validation is passed, the snap moves to candidate where it stays for some time to allow external testing
and integration, before it moves to stable.

## Supported versions
<!-- Include start supported versions -->
When reporting security issues against the core20 snap, only the latest 
release of the core20 snap is supported.

The core20 snap has regular releases that are fully automated. There are two 
types of security fixes that can be shipped with new versions of the core20 snap.

- Security fixes that are relevant to the files inside this repository.
- Security fixes that are carried from the official archives. I.e security fixes 
from debian packages carried inside the core20 snap.

<!-- Include end supported versions -->

## What qualifies as a security issue

Security vulnerabilities that apply to packages in the Ubuntu 20.04 LTS archives also shipped by the
core20 snap. Any vulnerability that allows the core20 snap to interfere outside 
of the intended restrictions also qualifies as a security issue, including vulnerabilities that
allows an unprivileged user on the local system to escalate privileges or cause a 
denial of service etc due to the use of the contents of the core20 snap on the system.

## Reporting a vulnerability

The easiest way to report a security issue is through
[GitHub](https://github.com/canonical/core20/security/advisories/new). See
[Privately reporting a security
vulnerability](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
for instructions.

The Ubuntu Core GitHub admins will be notified of the issue and will work with you
to determine whether the issue qualifies as a security issue and, if so, in
which component. We will then handle figuring out a fix, getting a CVE
assigned and coordinating the release of the fix to the Snapd snap and the
various Ubuntu releases and Linux distributions.

The [Ubuntu Security disclosure and embargo
policy](https://ubuntu.com/security/disclosure-policy) contains more
information about what you can expect when you contact us, and what we
expect from you.
