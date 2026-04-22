# CSS generator
lines = []
def a(s): lines.append(s)

a("/* -- CARDS -- */")
a(".card {")
a("  background: var(--bg-card);")
a("  border: 1px solid var(--bg-border);")
a("  border-radius: var(--radius);")
a("  padding: 1.25rem;")
a("  box-shadow: var(--shadow);")
a("}")
