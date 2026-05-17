#[must_use]
pub const fn greeting() -> &'static str {
    "hello from cargo-unit"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn returns_greeting() {
        assert_eq!(greeting(), "hello from cargo-unit");
    }
}
