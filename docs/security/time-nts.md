# Global Anycast NTS Time Architecture

Network Time Security (NTS) provides cryptographic authentication for the Network Time Protocol (NTP) using TLS 1.3 (RFC 8915). It prevents man-in-the-middle time manipulation attacks.

## Multi-Tiered Topology

`lusoris-cloud-images` implements a fault-tolerant multi-tier NTS topology configured in `/etc/chrony/sources.d/global-nts.sources`:

1. **Tier 1: Global Anycast NTS**
   - `server time.cloudflare.com iburst nts`
   - Provides worldwide single-digit millisecond latency via Anycast routing.
2. **Tier 2: European Stratum-1 National Metrology Institutes**
   - `ptbtime1.ptb.de` & `ptbtime2.ptb.de` (Physikalisch-Technische Bundesanstalt, Germany)
   - `nts.netnod.se` (Netnod, Sweden)
   - `ntp.time.nl` (SIDN Labs, Netherlands)
   - `ntp.3eck.net` (Switzerland)
3. **Tier 3: Graceful Fallback Pool**
   - `pool 2.ubuntu.pool.ntp.org iburst maxsources 4`
   - Ensures time synchronization continues without failure if an enterprise network firewall blocks TCP port 4460 (NTS-KE).

```mermaid
flowchart TD
    subgraph Client["Lusoris Guest OS (chrony daemon)"]
        Chrony["chrony (authselectmode mix)"]
        Step["makestep 1.0 3 · minsources 3"]
    end

    subgraph SecurityExchange["NTS Key Establishment (TLS 1.3 · TCP 4460)"]
        KE["NTS-KE Exchange<br/><small>AEAD Key & Cookie Negotiation</small>"]
    end

    subgraph TimeSources["Multi-Tiered Stratum-1 Time Infrastructure"]
        subgraph Tier1["Tier 1: Global Anycast NTS"]
            CF["time.cloudflare.com<br/><small>Anycast Edge Routing</small>"]
        end

        subgraph Tier2["Tier 2: European Metrology Institutes (Atomic Clocks)"]
            PTB["PTB Germany<br/><small>ptbtime1.ptb.de · ptbtime2.ptb.de</small>"]
            Netnod["Netnod Sweden<br/><small>nts.netnod.se</small>"]
            SIDN["SIDN Netherlands<br/><small>ntp.time.nl</small>"]
            Dreck["3eck Switzerland<br/><small>ntp.3eck.net</small>"]
        end

        subgraph Tier3["Tier 3: Graceful NTP Fallback"]
            Pool["2.ubuntu.pool.ntp.org<br/><small>UDP 123 Fallback if TCP 4460 Blocked</small>"]
        end
    end

    Chrony -->|TCP 4460 TLS 1.3| KE
    KE -->|Encrypted Cookies| Chrony
    Chrony -->|Authenticated UDP 123| CF & PTB & Netnod & SIDN & Dreck
    Chrony -.->|Unauthenticated UDP 123 Fallback| Pool
```

---

## Chrony Policy (`/etc/chrony/conf.d/global-policy.conf`)
- `authselectmode mix`: Prefers cryptographically authenticated NTS sources, gracefully falling back to standard NTP if NTS is unreachable.
- `makestep 1.0 3`: Steps the system clock if offset is greater than 1 second in the first 3 clock updates.
- `minsources 3`: Mandates at least 3 active sources for consensus before steering time.

