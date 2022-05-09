namespace Monitoring
{
    using Microsoft.ApplicationInsights.Channel;
    using Microsoft.ApplicationInsights.Extensibility;
    using Microsoft.Extensions.Configuration;

    public class ApplicationMapNodeNameInitializer : ITelemetryInitializer
    {
        public ApplicationMapNodeNameInitializer(IConfiguration configuration)
        {
            Name = configuration["ApplicationMapNodeName"];
        }

        public string Name { get; set; }

        public void Initialize(ITelemetry telemetry)
        {
            telemetry.Context.Cloud.RoleName = Name;
        }
    }
}

namespace Microsoft.Extensions.DependencyInjection
{
    using Microsoft.ApplicationInsights.Extensibility;
    using Monitoring;

    public static class ServiceCollectionExtensions
    {
        public static void AddApplicationMonitoring(this IServiceCollection services)
        {
            services.AddApplicationInsightsTelemetry();
            services.AddSingleton<ITelemetryInitializer, ApplicationMapNodeNameInitializer>();
        }
    }
}
