#!/usr/bin/env bash
# يشغّل الترحيلات والاختبارات على قاعدة PostgreSQL محلية مؤقتة.
# الاستخدام: supabase/tests/run_tests.sh   (يتطلب psql ومستخدم postgres)
set -euo pipefail
cd "$(dirname "$0")/.."
DB=badelha_test
PSQL=(psql -v ON_ERROR_STOP=1 -q -X)
dropdb --if-exists "$DB"; createdb "$DB"
"${PSQL[@]}" -d "$DB" -f tests/supabase_stub.sql
for f in migrations/*.sql; do
  echo "migrate: $f"
  "${PSQL[@]}" -d "$DB" -f "$f"
done
"${PSQL[@]}" -d "$DB" -o /dev/null -f tests/swap_flow_test.sql
echo "ALL TESTS PASSED"
