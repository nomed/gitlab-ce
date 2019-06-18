import invalidUrl from '~/lib/utils/invalid_url';

export default () => ({
  hasMetrics: false,
  showPanels: true,
  metricsEndpoint: null,
  environmentsEndpoint: null,
  deploymentsEndpoint: null,
  dashboardEndpoint: invalidUrl,
  useDashboardEndpoint: false,
  multipleDashboards: false,
  emptyState: 'gettingStarted',
  showEmptyState: true,
  groups: [],
  deploymentData: [],
  environments: [],
  metricsWithData: [],
  allDashboards: [],
});
