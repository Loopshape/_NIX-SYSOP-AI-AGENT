novelty = chaos
uncertainty = 1 - logos
score = novelty * uncertainty

if score > 0.4:
    conn.execute("""
    INSERT INTO curiosity (topic,novelty,uncertainty,score)
    VALUES (?,?,?,?)
    """,(prompt,novelty,uncertainty,score))

