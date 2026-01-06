# Pagy configuration
# https://ddnexus.github.io/pagy/

require "pagy/extras/overflow"
require "pagy/extras/metadata"

# Default items per page
Pagy::DEFAULT[:limit] = 12

# Overflow handling: return empty page instead of error
Pagy::DEFAULT[:overflow] = :empty_page

# Use symbols for size (Tailwind-friendly)
Pagy::DEFAULT[:size] = 7
