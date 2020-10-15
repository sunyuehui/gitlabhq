---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Alert integrations

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13203) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.4.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/42640) to [GitLab Core](https://about.gitlab.com/pricing/) in 12.8.

GitLab can accept alerts from any source via a webhook receiver. This can be configured generically or, in GitLab versions 13.1 and greater, you can configure
[External Prometheus instances](../metrics/alerts.md#external-prometheus-instances)
to use this endpoint.

## Configuration

You can either configure alerts to integrate with an [external Prometheus server](#external-prometheus-integration),
or provide a [generic HTTP endpoint](#generic-http-endpoint) to receive alerts
from other services.

### Generic HTTP Endpoint

Enabling the Generic HTTP Endpoint creates a unique HTTP endpoint that can receive alert payloads in JSON format. You can always
[customize the payload](#customizing-the-payload) to your liking.

You will need to activate the endpoint and obtain credentials to set up this integration:

1. Sign in to GitLab as a user with maintainer [permissions](../../user/permissions.md)
   for a project.
1. Navigate to **Settings > Operations** in your project.
1. Expand the **Alerts** section, and in the **Integration** dropdown menu, select **Generic**.
1. Toggle the **Active** alert setting to display the **URL** and **Authorization Key**
   for the webhook configuration.

### External Prometheus integration

For GitLab versions 13.1 and greater, please see [External Prometheus Instances](../metrics/alerts.md#external-prometheus-instances) to configure alerts for this integration.

## Customizing the payload

You can customize the payload by sending the following parameters. This applies to all types of integrations. All fields
other than `title` are optional:

| Property                  | Type            | Description |
| ------------------------- | --------------- | ----------- |
| `title`                   | String          | The title of the incident. Required. |
| `description`             | String          | A high-level summary of the problem. |
| `start_time`              | DateTime        | The time of the incident. If none is provided, a timestamp of the issue will be used. |
| `end_time`                | DateTime        | For existing alerts only. When provided, the alert is resolved and the associated incident is closed. |
| `service`                 | String          | The affected service. |
| `monitoring_tool`         | String          |  The name of the associated monitoring tool. |
| `hosts`                   | String or Array | One or more hosts, as to where this incident occurred. |
| `severity`                | String          | The severity of the alert. Must be one of `critical`, `high`, `medium`, `low`, `info`, `unknown`. Default is `critical`. |
| `fingerprint`             | String or Array | The unique identifier of the alert. This can be used to group occurrences of the same alert. |
| `gitlab_environment_name` | String          | The name of the associated GitLab [environment](../../ci/environments/index.md). This can be used to associate your alert to your environment. |

You can also add custom fields to the alert's payload. The values of extra
parameters aren't limited to primitive types (such as strings or numbers), but
can be a nested JSON object. For example:

```json
{ "foo": { "bar": { "baz": 42 } } }
```

TIP: **Payload size:**
Ensure your requests are smaller than the [payload application limits](../../administration/instance_limits.md#generic-alert-json-payloads).

Example request:

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Bearer <authorization_key>" \
  --header "Content-Type: application/json" \
  <url>
```

The `<authorization_key>` and `<url>` values can be found when configuring an alert integration.

Example payload:

```json
{
  "title": "Incident title",
  "description": "Short description of the incident",
  "start_time": "2019-09-12T06:00:55Z",
  "service": "service affected",
  "monitoring_tool": "value",
  "hosts": "value",
  "severity": "high",
  "fingerprint": "d19381d4e8ebca87b55cda6e8eee7385",
  "foo": {
    "bar": {
      "baz": 42
    }
  }
}
```

## Triggering test alerts

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3066) in GitLab Core in 13.2.

After a [project maintainer or owner](../../user/permissions.md)
configures an integration, you can trigger a test
alert to confirm your integration works properly.

1. Sign in as a user with Developer or greater [permissions](../../user/permissions.md).
1. Navigate to **Settings > Operations** in your project.
1. Click **Alerts endpoint** to expand the section.
1. Enter a sample payload in **Alert test payload** (valid JSON is required).
1. Click **Test alert payload**.

GitLab displays an error or success message, depending on the outcome of your test.

## Automatic grouping of identical alerts **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214557) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

In GitLab versions 13.2 and greater, GitLab groups alerts based on their
payload. When an incoming alert contains the same payload as another alert
(excluding the `start_time` and `hosts` attributes), GitLab groups these alerts
together and displays a counter on the [Alert Management List](./incidents.md)
and details pages.

If the existing alert is already `resolved`, GitLab creates a new alert instead.

![Alert Management List](./img/alert_list_v13_1.png)

### Link to your Opsgenie Alerts

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3066) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

You can monitor alerts using a GitLab integration with [Opsgenie](https://www.atlassian.com/software/opsgenie).

If you enable the Opsgenie integration, you can't have other GitLab alert
services, such as [Generic Alerts](generic_alerts.md) or Prometheus alerts,
active at the same time.

To enable Opsgenie integration:

1. Sign in as a user with Maintainer or Owner [permissions](../../user/permissions.md).
1. Navigate to **Operations > Alerts**.
1. In the **Integrations** select box, select **Opsgenie**.
1. Select the **Active** toggle.
1. In the **API URL** field, enter the base URL for your Opsgenie integration,
   such as `https://app.opsgenie.com/alert/list`.
1. Select **Save changes**.

After you enable the integration, navigate to the Alerts list page at
**Operations > Alerts**, and then select **View alerts in Opsgenie**.