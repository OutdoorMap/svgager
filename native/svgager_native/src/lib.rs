use rustler::{Binary, Env, OwnedBinary};

mod converter;
use converter::convert_svg_to_image;

#[rustler::nif]
fn convert_svg<'a>(
    env: Env<'a>,
    svg_data: String,
    format: String,
    width: Option<u32>,
    height: Option<u32>,
    background_color: Option<String>,
    replacements: Vec<(String, String)>,
) -> Result<Binary<'a>, String> {
    let data = convert_svg_to_image(
        svg_data,
        format,
        width,
        height,
        background_color,
        replacements,
    )?;

    let mut binary =
        OwnedBinary::new(data.len()).ok_or_else(|| "Failed to allocate binary".to_string())?;
    binary.as_mut_slice().copy_from_slice(&data);

    Ok(binary.release(env))
}

rustler::init!("Elixir.Svgager.Native");
