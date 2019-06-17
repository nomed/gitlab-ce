# Manage feature flags

Feature flags can be used to gradually roll out changes, be
it a new feature, or a performance improvement. By using feature flags, we can
comfortably measure the impact of our changes, while still being able to easily
disable those changes, without having to revert an entire release.

## Feature flags for user applications

This document only covers feature flags used in the development of GitLab
itself. Feature flags in deployed user applications can be found at
[Feature Flags feature documentation](../user/project/operations/feature_flags.md).

## Feature flags in GitLab development

The following highlights should be considered when deciding if feature flags should be leveraged:

* By default, the feature flags should be **off**.
* Feature flags should remain in the codebase for as short period as possible to reduce the need for feature flag accounting.
* Person operating with feature flags is responsible for clearly communicating the status of a feature behind the feature flag with responsible stakeholders.
* Merge requests that make changes hidden behind a feature flag, or remove an
existing feature flag because a feature is deemed stable should have the ~"feature flag"
label assigned.

In order to build the final release and present the feature for self-hosted
customers, the feature flag should be removed. This should happen before the
22nd, _at least_ 2 days before. Take into consideration that such action can make the feature
available on GitLab.com shortly after the change to the feature flag is merged.

While rare, release managers may decide to reject picking or revert a change in a stable
branch, even when feature flags are used. This might be necessary if the changes
are deemed problematic, too invasive, or there simply isn't enough time to
properly test how the changes behave on GitLab.com.

One might be tempted to think that feature flags will delay the release of a
feature by at least one month (= one release). This is not the case. A feature
flag does not have to stick around for a specific amount of time
(e.g. at least one release), instead they should stick around until the feature
is deemed stable. Stable means it works on GitLab.com without causing any
problems, such as outages.

For more information on how to add a feature flag, and how to roll out changes using feature flags, read [through the documentation](rolling_out_changes_using_feature_flags.md).

### When to use feature flags

Starting with GitLab 11.4, developers are required to use feature flags for
non-trivial changes. Such changes include:

- New features (e.g. a new merge request widget, epics, etc).
- Complex performance improvements that may require additional testing in
  production, such as rewriting complex queries.
- Invasive changes to the user interface, such as a new navigation bar or the
  removal of a sidebar.
- Adding support for importing projects from a third-party service.

In all cases, those working on the changes can best decide if a feature flag is
necessary. For example, changing the color of a button doesn't need a feature
flag, while changing the navigation bar definitely needs one. In case you are
uncertain if a feature flag is necessary, simply ask about this in the merge
request, and those reviewing the changes will likely provide you with an answer.

When using a feature flag for UI elements, make sure to _also_ use a feature
flag for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until it is enabled.

### The cost of feature flags

When reading the above, one might be tempted to think this procedure is going to
add a lot of work. Fortunately, this is not the case, and we'll show why. For
this example we'll specify the cost of the work to do as a number, ranging from
0 to infinity. The greater the number, the more expensive the work is. The cost
does _not_ translate to time, it's just a way of measuring complexity of one
change relative to another.

Let's say we are building a new feature, and we have determined that the cost of
this is 10. We have also determined that the cost of adding a feature flag check
in a variety of places is 1. If we do not use feature flags, and our feature
works as intended, our total cost is 10. This however is the best case scenario.
Optimising for the best case scenario is guaranteed to lead to trouble, whereas
optimising for the worst case scenario is almost always better.

To illustrate this, let's say our feature causes an outage, and there's no
immediate way to resolve it. This means we'd have to take the following steps to
resolve the outage:

1. Revert the release.
1. Perform any cleanups that might be necessary, depending on the changes that
   were made.
1. Revert the commit, ensuring the "master" branch remains stable. This is
   especially necessary if solving the problem can take days or even weeks.
1. Pick the revert commit into the appropriate stable branches, ensuring we
   don't block any future releases until the problem is resolved.

As history has shown, these steps are time consuming, complex, often involve
many developers, and worst of all: our users will have a bad experience using
GitLab.com until the problem is resolved.

Now let's say that all of this has an associated cost of 10. This means that in
the worst case scenario, which we should optimise for, our total cost is now 20.

If we had used a feature flag, things would have been very different. We don't
need to revert a release, and because feature flags are disabled by default we
don't need to revert and pick any Git commits. In fact, all we have to do is
disable the feature, and in the worst case, perform cleanup. Let's say that
the cost of this is 2. In this case, our best case cost is 11: 10 to build the
feature, and 1 to add the feature flag. The worst case cost is now 13: 10 to
build the feature, 1 to add the feature flag, and 2 to disable and clean up.

Here we can see that in the best case scenario the work necessary is only a tiny
bit more compared to not using a feature flag. Meanwhile, the process of
reverting our changes has been made significantly and reliably cheaper.

In other words, feature flags do not slow down the development process. Instead,
they speed up the process as managing incidents now becomes _much_ easier. Once
continuous deployments are easier to perform, the time to iterate on a feature
is reduced even further, as you no longer need to wait weeks before your changes
are available on GitLab.com.

#### Feature groups

This document was moved to [another location](rolling_out_changes_using_feature_flags.md).

#### Developing with feature flags

This document was moved to [another location](rolling_out_changes_using_feature_flags.md).

#### Frontend

This document was moved to [another location](rolling_out_changes_using_feature_flags.md).

#### Specs

This document was moved to [another location](rolling_out_changes_using_feature_flags.md).

#### Enabling a feature flag (in production)

This document was moved to [another location](rolling_out_changes_using_feature_flags.md).
