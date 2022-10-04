use crate::Status;
use opentelemetry::global;
use tracing::Level;
use tracing_subscriber::{
    fmt::{self, writer::MakeWriterExt},
    layer::SubscriberExt,
    util::SubscriberInitExt,
};

pub struct Tracing;

impl Tracing {
    pub fn setup(name: &str) -> Result<(), Status> {
        global::set_text_map_propagator(opentelemetry_jaeger::Propagator::new());

        let tracer = match opentelemetry_jaeger::new_agent_pipeline()
            .with_service_name(name)
            .install_simple()
        {
            Ok(tracer) => tracer,
            Err(e) => {
                eprintln!("{e}");
                return Err(Status::new("Failed to setup tracing", e));
            }
        };

        let opentelemetry = tracing_opentelemetry::layer().with_tracer(tracer);
        match tracing_subscriber::registry()
            .with(opentelemetry)
            // Continue logging to stdout
            .with(
                fmt::Layer::new()
                    .with_writer(std::io::stdout.with_max_level(Level::INFO))
                    .pretty(),
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
