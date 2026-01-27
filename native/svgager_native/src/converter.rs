use image::{
    codecs::jpeg::JpegEncoder, codecs::png::PngEncoder, ImageBuffer, ImageEncoder, ImageFormat,
    Rgba,
};
use std::io::Cursor;

pub fn convert_svg_to_image(
    svg_data: String,
    format: String,
    width: Option<u32>,
    height: Option<u32>,
    background_color: Option<String>,
    replacements: Vec<(String, String)>,
) -> Result<Vec<u8>, String> {
    // Step 1: Preprocess SVG with string replacements
    let mut processed_svg = svg_data;
    for (search, replace) in replacements {
        processed_svg = processed_svg.replace(&search, &replace);
    }

    // Step 2: Parse SVG
    let opt = usvg::Options::default();
    let tree = usvg::Tree::from_str(&processed_svg, &opt)
        .map_err(|e| format!("Failed to parse SVG: {}", e))?;

    // Step 3: Determine output dimensions
    let svg_size = tree.size();
    let (out_width, out_height) = match (width, height) {
        (Some(w), Some(h)) => (w, h),
        (Some(w), None) => {
            let aspect_ratio = svg_size.height() / svg_size.width();
            (w, (w as f32 * aspect_ratio) as u32)
        }
        (None, Some(h)) => {
            let aspect_ratio = svg_size.width() / svg_size.height();
            ((h as f32 * aspect_ratio) as u32, h)
        }
        (None, None) => (svg_size.width() as u32, svg_size.height() as u32),
    };

    // Step 4: Create pixmap and render SVG
    let mut pixmap = tiny_skia::Pixmap::new(out_width, out_height)
        .ok_or_else(|| "Failed to create pixmap".to_string())?;

    // Apply background color for non-PNG formats
    let is_png = format.to_lowercase() == "png";
    if !is_png {
        let bg_color = background_color.unwrap_or_else(|| "FFFFFF".to_string());
        let rgb = parse_hex_color(&bg_color)?;
        pixmap.fill(tiny_skia::Color::from_rgba8(rgb.0, rgb.1, rgb.2, 255));
    }

    // Render SVG to pixmap
    let transform = tiny_skia::Transform::from_scale(
        out_width as f32 / svg_size.width(),
        out_height as f32 / svg_size.height(),
    );

    resvg::render(&tree, transform, &mut pixmap.as_mut());

    // Step 5: Encode to requested format
    let image_data = pixmap.data();
    encode_image(image_data, out_width, out_height, &format, is_png)
}

fn parse_hex_color(hex: &str) -> Result<(u8, u8, u8), String> {
    let hex = hex.trim_start_matches('#');

    if hex.len() != 6 {
        return Err(format!(
            "Invalid hex color: must be 6 characters (RRGGBB), got {}",
            hex.len()
        ));
    }

    let r = u8::from_str_radix(&hex[0..2], 16)
        .map_err(|_| format!("Invalid hex color: could not parse red component"))?;
    let g = u8::from_str_radix(&hex[2..4], 16)
        .map_err(|_| format!("Invalid hex color: could not parse green component"))?;
    let b = u8::from_str_radix(&hex[4..6], 16)
        .map_err(|_| format!("Invalid hex color: could not parse blue component"))?;

    Ok((r, g, b))
}

fn encode_image(
    data: &[u8],
    width: u32,
    height: u32,
    format: &str,
    has_alpha: bool,
) -> Result<Vec<u8>, String> {
    let mut output = Vec::new();
    let cursor = Cursor::new(&mut output);

    match format.to_lowercase().as_str() {
        "png" => {
            let encoder = PngEncoder::new(cursor);
            encoder
                .write_image(data, width, height, image::ExtendedColorType::Rgba8)
                .map_err(|e| format!("Failed to encode PNG: {}", e))?;
        }
        "jpg" | "jpeg" => {
            // Convert RGBA to RGB for JPEG
            let rgb_data = rgba_to_rgb(data);
            let encoder = JpegEncoder::new_with_quality(cursor, 90);
            encoder
                .write_image(&rgb_data, width, height, image::ExtendedColorType::Rgb8)
                .map_err(|e| format!("Failed to encode JPEG: {}", e))?;
        }
        "gif" => {
            // For GIF, we need to use the image crate's DynamicImage
            let img = if has_alpha {
                ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, data.to_vec())
                    .ok_or_else(|| "Failed to create image buffer".to_string())?
            } else {
                ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, data.to_vec())
                    .ok_or_else(|| "Failed to create image buffer".to_string())?
            };

            image::DynamicImage::ImageRgba8(img)
                .write_to(&mut Cursor::new(&mut output), ImageFormat::Gif)
                .map_err(|e| format!("Failed to encode GIF: {}", e))?;
        }
        "webp" => {
            // For WebP, we need to convert to DynamicImage
            let img = ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, data.to_vec())
                .ok_or_else(|| "Failed to create image buffer".to_string())?;

            image::DynamicImage::ImageRgba8(img)
                .write_to(&mut Cursor::new(&mut output), ImageFormat::WebP)
                .map_err(|e| format!("Failed to encode WebP: {}", e))?;
        }
        _ => return Err(format!("Unsupported format: {}", format)),
    }

    Ok(output)
}

fn rgba_to_rgb(rgba_data: &[u8]) -> Vec<u8> {
    let mut rgb_data = Vec::with_capacity(rgba_data.len() * 3 / 4);

    for chunk in rgba_data.chunks(4) {
        rgb_data.push(chunk[0]); // R
        rgb_data.push(chunk[1]); // G
        rgb_data.push(chunk[2]); // B
                                 // Skip alpha channel (chunk[3])
    }

    rgb_data
}
