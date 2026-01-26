confidence = logos
anxiety = chaos
drive = nomos

conn.execute("""
INSERT INTO emotion (genesis,confidence,anxiety,drive)
VALUES (?,?,?,?)
""",(genesis,confidence,anxiety,drive))

