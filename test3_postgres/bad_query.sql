SELECT a.*
FROM users u
RIGHT JOIN addresses a
  ON a.user_id = u.id
WHERE u.id = 42
ORDER BY a.created_at DESC;