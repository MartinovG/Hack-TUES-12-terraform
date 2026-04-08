# WAF rules

1. AWSManagedRulesCommonRuleSet (Priority 1)
OWASP Top 10 Protection

Protects against common web exploits like:
Cross-Site Scripting (XSS) - malicious scripts in web pages
Local File Inclusion (LFI) - attempts to access server files
Remote File Inclusion (RFI) - attempts to include remote files
Command injection - executing arbitrary commands
Path traversal - accessing files outside intended directories (e.g., ../../etc/passwd)
Bad/malicious user agents and bots
This is the most comprehensive baseline protection

2. AWSManagedRulesKnownBadInputsRuleSet (Priority 2)
Known Malicious Patterns

Blocks requests with patterns known to be malicious:
Exploit attempts with known CVE patterns
Log4j vulnerability attempts (Log4Shell)
Malformed or suspicious request patterns
Known attack signatures from AWS threat intelligence
Constantly updated by AWS with new threat patterns

3. AWSManagedRulesSQLiRuleSet (Priority 3)
SQL Injection Protection

Specifically protects against SQL injection attacks:
Detects SQL commands in request parameters (' OR 1=1--, UNION SELECT, etc.)
Protects query strings, URI paths, body content
Prevents database manipulation attempts
Critical for protecting your DocumentDB/MongoDB backend

4. RateLimitRule (Priority 4)
DDoS Protection / Rate Limiting

Blocks IPs that exceed 2000 requests per 5 minutes
Prevents:
Brute force attacks (password guessing)
DDoS attacks from single sources
API abuse and scraping
Resource exhaustion
Tracks by IP address, so legitimate traffic from different IPs isn't affected

5. GeoBlockingRule (Priority 5)
Geographic Access Control (Optional - only active if blocked_countries configured)

Blocks traffic from specific countries
Use cases:
Compliance requirements (GDPR, data sovereignty)
Reducing attack surface from high-risk regions
License/business restrictions
Currently not active unless you set blocked_countries = ["CN", "RU", ...] in your terragrunt config

# Additional Features:

CloudWatch Metrics - All rules send metrics for monitoring
Sampled Requests - Logs sample of blocked/allowed requests for analysis
Redacted Fields - Strips sensitive headers (authorization, cookie) from logs for security
30-day log retention - Stores WAF logs in CloudWatch for audit/forensics