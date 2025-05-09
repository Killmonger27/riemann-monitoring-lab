#!/usr/bin/env ruby

require 'riemann/client'
require 'faker'
require 'socket'

# Configuration
RIEMANN_HOST = ENV['RIEMANN_HOST'] || 'riemann'
RIEMANN_PORT = (ENV['RIEMANN_PORT'] || 5555).to_i  # Port corrigé (TCP/UDP)
INTERVAL = (ENV['INTERVAL'] || 30).to_i # secondes entre les métriques
HOSTNAME = Socket.gethostname

# Afficher les informations de démarrage
puts "🚀 Agent de test Riemann démarré avec configuration:"
puts "  - Host: #{RIEMANN_HOST}"
puts "  - Port: #{RIEMANN_PORT}"
puts "  - Intervalle: #{INTERVAL} secondes"
puts "  - Hostname: #{HOSTNAME}"

# Création du client Riemann
client = Riemann::Client.new(
  host: RIEMANN_HOST,
  port: RIEMANN_PORT
)

puts "📡 Client démarré, envoi de métriques à #{RIEMANN_HOST}:#{RIEMANN_PORT} toutes les #{INTERVAL} secondes..."

# Tentative de connexion initiale
begin
  client.tcp << {
    service: "agent-startup",
    state: "ok",
    description: "Agent de test démarré",
    host: HOSTNAME,
    tags: ["startup"]
  }
  puts "✅ Connexion test à Riemann réussie"
rescue => e
  puts "❌ Erreur de connexion initiale: #{e.message}"
  puts "⚠️ Tentative d'envoi de métriques malgré l'erreur..."
end

loop do
  begin
    # Métriques CPU
    cpu_usage = rand(0.1..0.95)
    client << {
      service: "cpu-usage",
      metric: cpu_usage,
      state: cpu_usage > 0.8 ? "critical" : cpu_usage > 0.5 ? "warning" : "ok",
      tags: ["system", "cpu"],
      host: HOSTNAME,
      description: "Utilisation CPU",
      ttl: INTERVAL * 2
    }

    # Métriques mémoire
    memory_usage = rand(0.2..0.85)
    client << {
      service: "memory-usage",
      metric: memory_usage,
      state: memory_usage > 0.8 ? "critical" : memory_usage > 0.6 ? "warning" : "ok",
      tags: ["system", "memory"],
      host: HOSTNAME,
      description: "Utilisation mémoire",
      ttl: INTERVAL * 2
    }

    # Latence réseau simulée
    network_latency = rand(1..150)
    client << {
      service: "network-latency",
      metric: network_latency,
      state: network_latency > 100 ? "critical" : network_latency > 50 ? "warning" : "ok",
      tags: ["network", "latency"],
      host: HOSTNAME,
      description: "Latence réseau (ms)",
      ttl: INTERVAL * 2
    }

    # Événement applicatif aléatoire (simulé)
    if rand < 0.1 # 10% de chance
      client << {
        service: "application-event",
        state: ["ok", "warning", "critical"].sample,
        tags: ["application"],
        host: HOSTNAME,
        description: "Événement: #{Faker::Hacker.say_something_smart}",
        ttl: INTERVAL * 5
      }
    end

    puts "📊 Métriques envoyées: CPU #{(cpu_usage * 100).round(2)}%, MEM #{(memory_usage * 100).round(2)}%, Latence: #{network_latency}ms"
  rescue => e
    puts "❌ Erreur: #{e.message}"
    puts "🔄 Tentative de reconnexion au prochain cycle..."
    
    # Tentative de recréation du client
    begin
      client = Riemann::Client.new(
        host: RIEMANN_HOST,
        port: RIEMANN_PORT
      )
    rescue => reconnect_error
      puts "❌ Échec de reconnexion: #{reconnect_error.message}"
    end
  end

  sleep INTERVAL
end