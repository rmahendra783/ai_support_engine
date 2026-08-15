puts "Cleaning existing tickets..."
Support::Ticket.destroy_all

# =========================================================================
# Part 1: Historical Knowledge Base (RAG ke context ke liye resolved tickets)
# =========================================================================
puts "\n1. Seeding Historical Resolved Tickets (Knowledge Base)..."

resolved_knowledge_base = [
  {
    title: "Double payment deducted on checkout",
    description: "Customer was charged twice for order via UPI. Extra money debited from bank.",
    resolution: "Verified duplicate transaction ID via payment gateway dashboard. Initiated full refund of the duplicate amount. Refund ARN shared with customer. Credit timeline: 3-5 business days."
  },
  {
    title: "Unable to reset account password or receive OTP",
    description: "Customer requested password reset link multiple times but received no email in inbox or spam folder.",
    resolution: "Investigated SendGrid bounce logs; customer domain had spam bounce suppression active. Cleared suppression list, whitelisted email, and triggered a secure one-time reset link."
  },
  {
    title: "Database connection pool exhaustion 500 error",
    description: "API servers throwing 500 Internal Server Error due to PG::ConnectionBad connection pool limits.",
    resolution: "Increased ActiveRecord DB pool size from 5 to 25 in database.yml and enabled PgBouncer transaction-level connection pooling on production cluster."
  },
  {
    title: "Suspicious login from unauthorized location",
    description: "Customer noticed unknown login attempt from another state/country IP address.",
    resolution: "Immediately invalidated all active JWT auth tokens and user sessions from Redis. Enabled mandatory Two-Factor Authentication (2FA) and prompted user for security pin reset."
  }
]

resolved_knowledge_base.each do |data|
  # Sync mode mein save karke vector calculate kar rahe hain taaki seed ke baad knowledge base ready ho
  ticket = Support::Ticket.new(
    title: data[:title],
    description: data[:description],
    resolution: data[:resolution],
    status: "processed"
  )

  # Embedding calculate karke save karna
  analyzer = Ai::TicketAnalyzerService.new(ticket).call
  ticket.category = analyzer[:category]
  ticket.priority = analyzer[:priority]
  ticket.sentiment = analyzer[:sentiment]
  ticket.embedding = analyzer[:embedding]
  ticket.save!

  puts "✓ Knowledge Base Ticket ##{ticket.id} indexed: #{ticket.title}"
end

# =========================================================================
# Part 2: Open / Sample Tickets (Jinka AI auto-draft test kiya ja sake)
# =========================================================================
puts "\n2. Seeding Sample Unresolved Tickets..."

open_tickets = [
  {
    title: "Dark mode request for web dashboard",
    description: "Would love to have an option to switch to a dark theme in the web dashboard for late-night work."
  }
]

open_tickets.each do |data|
  ticket = Support::Ticket.create!(data)
  puts "✓ Created Open Ticket ##{ticket.id}: #{ticket.title}"
end

puts "\nDatabase successfully seeded with RAG Knowledge Base and Sample Tickets!"
