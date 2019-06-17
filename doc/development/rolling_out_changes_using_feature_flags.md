# Rolling out changes using feature flags
## Developing with feature flags

In general, it's better to have a group- or user-based gate, and you should prefer
it over the use of percentage gates. This would make debugging easier, as you
filter for example logs and errors based on actors too. Furthermore, this allows
for enabling for the `gitlab-org` or `gitlab-com` group first, while the rest of
the users aren't impacted.

```ruby
# Good
Feature.enabled?(:feature_flag, project)

# Avoid, if possible
Feature.enabled?(:feature_flag)
```

To use feature gates based on actors, the model needs to respond to
`flipper_id`. For example, to enable for the Foo model:

```ruby
class Foo < ActiveRecord::Base
  include FeatureGate
end
```

Features that are developed and are intended to be merged behind a feature flag
should not include a changelog entry. The entry should be added in the merge
request removing the feature flags.

In the rare case that you need the feature flag to be on automatically, use
`default_enabled: true` when checking:

```ruby
Feature.enabled?(:feature_flag, project, default_enabled: true)
```

For more information about rolling out changes using feature flags, refer to the
[Rolling out changes using feature flags](rolling_out_changes_using_feature_flags.md)
guide.

### Frontend

For frontend code you can use the method `push_frontend_feature_flag`, which is
available to all controllers that inherit from `ApplicationController`. Using
this method you can expose the state of a feature flag as follows:

```ruby
before_action do
  push_frontend_feature_flag(:vim_bindings)
end

def index
  # ...
end

def edit
  # ...
end
```

You can then check for the state of the feature flag in JavaScript as follows:

```javascript
if ( gon.features.vimBindings ) {
  // ...
}
```

The name of the feature flag in JavaScript will always be camelCased, meaning
that checking for `gon.features.vim_bindings` would not work.

### Specs

In the test environment `Feature.enabled?` is stubbed to always respond to `true`,
so we make sure behavior under feature flag doesn't go untested in some non-specific
contexts.

Whenever a feature flag is present, make sure to test _both_ states of the
feature flag.

See the
[testing guide](testing_guide/best_practices.md#feature-flags-in-tests)
for information and examples on how to stub feature flags in tests.

### Enabling a feature flag (in development)

In the rails console (`rails c`), enter the following command to enable your feature flag

```ruby
Feature.enable(:feature_flag_name)
```

## Access for enabling a feature flag in production

In order to be able to turn on/off features behind feature flags in any of the
GitLab Inc. provided environments such as staging and production, you need to
have access to the chatops bot. Chatops bot is currently running on the ops instance,
which is different from GitLab.com or dev.gitlab.org.

In order to be added to the specific repository, login to `ops.gitlab.net`.
This instance is configured to allow access only to GitLab Inc. employees.

Once your account is created, go to the `#production` channel in Slack and ask
to be added to chatops project:

```
/chatops run member add USERNAME gitlab-com/chatops --ops
```

where `USERNAME` is your username on ops.gitlab.net.


## Rolling out changes

The procedure of using feature flags is straightforward, and similar to not
using them. You add the necessary tests (make sure to test both the on and off
states of your feature flag(s)), make sure they all pass, have the code
reviewed, etc. You then submit your merge request, and add the ~"feature flag"
label. This label is used to signal to release managers that your changes are
hidden behind a feature flag and that it is safe to pick the MR into a stable
branch, without the need for an exception request.

When the changes are deployed it is time to start rolling out the feature to our
users. The exact procedure of rolling out a change is unspecified, as this can
vary from change to change. However, in general we recommend rolling out changes
incrementally, instead of enabling them for everybody right away. We also
recommend you to _not_ enable a feature _before_ the code is being deployed.
This allows you to separate rolling out a feature from a deploy, making it
easier to measure the impact of both separately.

GitLab's feature library (using
[Flipper](https://github.com/jnunemaker/flipper), and covered in the [Feature
Flags](feature_flags.md) guide) supports rolling out changes to a percentage of
users. This in turn can be controlled using [GitLab
chatops](../ci/chatops/README.md).

For an up to date list of feature flag commands please see [the source
code](https://gitlab.com/gitlab-com/chatops/blob/master/lib/chatops/commands/feature.rb).
Note that all the examples in that file must be preceded by
`/chatops run`.

If you get an error "Whoops! This action is not allowed. This incident
will be reported." that means your Slack account is not allowed to
change feature flags. To test if you are allowed to do anything at all,
run:

```
/chatops run feature --help
```

For example, to enable a feature for 25% of all users, run the following in
Slack:

```
/chatops run feature set new_navigation_bar 25
```

This will enable the feature for GitLab.com, with `new_navigation_bar` being the
name of the feature. We can also enable the feature for <https://dev.gitlab.org>
or <https://staging.gitlab.com>:

```
/chatops run feature set new_navigation_bar 25 --dev
/chatops run feature set new_navigation_bar 25 --staging
```

If you are not certain what percentages to use, simply use the following steps:

1. 25%
1. 50%
1. 75%
1. 100%

Between every step you'll want to wait a little while and monitor the
appropriate graphs on <https://dashboards.gitlab.net>. The exact time to wait
may differ. For some features a few minutes is enough, while for others you may
want to wait several hours or even days. This is entirely up to you, just make
sure it is clearly communicated to your team, and the Production team if you
anticipate any potential problems.

Feature gates can also be actor based, for example a feature could first be
enabled for only the `gitlab-ce` project. The project is passed by supplying a
`--project` flag:

```
/chatops run feature set --project=gitlab-org/gitlab-ce some_feature true
```

For groups the `--group` flag is available:

```
/chatops run feature set --group=gitlab-org some_feature true
```

## Implicit feature flags

The [`Project#feature_available?`][project-fa],
[`Namespace#feature_available?`][namespace-fa] (EE), and
[`License.feature_available?`][license-fa] (EE) methods all implicitly check for
a feature flag by the same name as the provided argument.

For example if a feature is license-gated, there's no need to add an additional
explicit feature flag check since the flag will be checked as part of the
`License.feature_available?` call. Similarly, there's no need to "clean up" a
feature flag once the feature has reached general availability.

You'd still want to use an explicit `Feature.enabled?` check if your new feature
isn't gated by a License or Plan.

[project-fa]: https://gitlab.com/gitlab-org/gitlab-ee/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/app/models/project_feature.rb#L63-68
[namespace-fa]: https://gitlab.com/gitlab-org/gitlab-ee/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/ee/app/models/ee/namespace.rb#L71-85
[license-fa]: https://gitlab.com/gitlab-org/gitlab-ee/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/ee/app/models/license.rb#L293-300

### Undefined feature flags default to "on"

An important side-effect of the [implicit feature flags](#implicit-feature-flags)
mentioned above is that unless the feature is explicitly disabled or limited to a
percentage of users, the feature flag check will default to `true`.

As an example, if you were to ship the backend half of a feature behind a flag,
you'd want to explicitly disable that flag until the frontend half is also ready
to be shipped. You can do this via ChatOps:

```
/chatops run feature set some_feature 0
```

Note that you can do this at any time, even before the merge request using the
flag has been merged!

### Cleaning up

Once a change is deemed stable, submit a new merge request to remove the
feature flag. This ensures the change is available to all users and self-hosted
instances. Make sure to add the ~"feature flag" label to this merge request so
release managers are aware the changes are hidden behind a feature flag. If the
merge request has to be picked into a stable branch, make sure to also add the
appropriate "Pick into X" label (e.g. "Pick into XX.X").

When a feature gate has been removed from the code base, the value still exists
in the database. This can be removed through ChatOps:

```
/chatops run feature delete some_feature
```

## Feature groups

Starting from GitLab 9.4 we support feature groups via
[Flipper groups](https://github.com/jnunemaker/flipper/blob/v0.10.2/docs/Gates.md#2-group).

Feature groups must be defined statically in `lib/feature.rb` (in the
`.register_feature_groups` method), but their implementation can obviously be
dynamic (querying the DB etc.).

Once defined in `lib/feature.rb`, you will be able to activate a
feature for a given feature group via the [`feature_group` param of the features API](../api/features.md#set-or-create-a-feature)

For GitLab.com, [team members have access to feature flags through Chatops](chatops_on_gitlabcom.md). Only
percentage gates are supported at this time. Setting a feature to be used 50% of
the time, you should execute `/chatops run feature set my_feature_flag 50`.

### When to use feature flags

This document was moved to [another location](feature_flags.md).

### The cost of feature flags

This document was moved to [another location](feature_flags.md).
