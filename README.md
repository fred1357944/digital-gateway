# Digital Gateway

Digital goods marketplace with MVT (Minimum Viable Test) validation.

## Tech Stack

- Ruby 3.4.8 / Rails 8.1
- PostgreSQL
- Tailwind CSS v4
- Devise (authentication)
- Gemini AI (content validation)

## Development

```bash
bundle install
rails db:setup
rails server
```

## Deployment

Deployed on Zeabur. See `docs/SCALING_GUIDE.md` for scaling instructions.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `RAILS_MASTER_KEY` | Rails credentials key |
| `SECRET_KEY_BASE` | Session secret |
| `GEMINI_API_KEY` | Optional: Gemini AI API key |
