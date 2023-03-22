use crate::Status;
use tracing::Level;
use tracing_stackdriver::CloudTraceConfiguration;
use tracing_subscriber::{
    fmt::writer::MakeWriterExt, layer::SubscriberExt, util::SubscriberInitExt,
};

pub struct Tracing;

impl Tracing {
    pub fn setup(name: &str) -> Result<(), Status> {
        opentelemetry::global::set_text_map_propagator(opentelemetry_jaeger::Propagator::new());

        let jaeger_tracer = match opentelemetry_jaeger::new_agent_pipeline()
            .with_service_name(name)
            .install_simple()
        {
            Ok(tracer) => tracer,
            Err(e) => {
                eprintln!("{e}");
                return Err(Status::new("Failed to setup tracing", e));
            }
        };

        match tracing_subscriber::registry()
            .with(tracing_opentelemetry::layer().with_tracer(jaeger_tracer))
            .with(
                // Log also to stdout.
                tracing_subscriber::fmt::Layer::new()
                    .with_writer(std::io::stdout.with_max_level(Level::INFO)),
            )
            .try_init()
        {
            Ok(()) => Ok(()),
            Err(e) => {
                eprintln!("{e}");
                return Err(Status::new("Failed to setup tracing", e));
            }
        }
    }

    pub fn setup_prod(project_id: &str) -> Result<(), Status> {
        opentelemetry::global::set_text_map_propagator(opentelemetry_jaeger::Propagator::new());

        match tracing_subscriber::registry()
            .with(tracing_opentelemetry::layer())
            .with(
                tracing_stackdriver::layer().enable_cloud_trace(CloudTraceConfiguration {
                    project_id: project_id.to_owned(),
                }),
            )
            .try_init()
        {
            Ok(()) => Ok(()),
            Err(e) => {
                eprintln!("{e}");
                return Err(Status::new("Failed to setup tracing", e));
            }
        }
    }
}
