# frozen_string_literal: true

# Lockbox encryption configuration
# IMPORTANT: Use stable key from environment variable
Lockbox.master_key = ENV["LOCKBOX_MASTER_KEY"]
