# Best Practices Badge vs. Scorecards

The OpenSSF has several different systems for evaluating the
security of open source software (OSS),
including [OpenSSF Scorecards](https://github.com/ossf/scorecard)
and the OpenSSF Best Practices badge.
Both have their value; Scorecards even includes
the OpenSSF Best Practices Badge as one of its information sources.

Here is a quick comparison between them, so you can understand their role:

* Scorecards - This is *entirely* automated.
    * Pros: You can evaluate *any* OSS project with it, immediately.
    * Cons: It focuses on what can be automatically measured (not necessarily what's important, many of its automated measures don't detect many situations (e.g., its SAST tool detector won't notice many SAST tools), and it currently only works on projects primarily hosted on GitHub (many OSS projects aren't). Note that the best practices badge value is one of the scorecard values.
* Best practices badge - this requires projects to fill in a form.
    * Pros: It tries to focus on what's important (not what's easily automated); it can handle arbitrary situations & hosting platforms.
    * Cons: It requires projects to work with it (instead of just happening automatically) so you won't get results for many OSS projects.
