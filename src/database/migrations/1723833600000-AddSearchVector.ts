import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSearchVector1723833600000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Add tsvector column
    await queryRunner.query(`
      ALTER TABLE hostels
      ADD COLUMN search_vector tsvector;
    `);

    // 2. Populate from existing data
    await queryRunner.query(`
      UPDATE hostels
      SET search_vector =
        setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(address, '')), 'C') ||
        setweight(to_tsvector('english', coalesce(city, '')), 'C');
    `);

    // 3. GIN index for fast lookups
    await queryRunner.query(`
      CREATE INDEX idx_hostels_search_vector
      ON hostels USING GIN (search_vector);
    `);

    // 4. Trigger to keep it in sync on INSERT/UPDATE
    await queryRunner.query(`
      CREATE OR REPLACE FUNCTION hostels_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(NEW.name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(NEW.address, '')), 'C') ||
          setweight(to_tsvector('english', coalesce(NEW.city, '')), 'C');
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    await queryRunner.query(`
      CREATE TRIGGER trg_hostels_search_vector
      BEFORE INSERT OR UPDATE OF name, description, address, city
      ON hostels
      FOR EACH ROW
      EXECUTE FUNCTION hostels_search_vector_update();
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TRIGGER IF EXISTS trg_hostels_search_vector ON hostels;`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS hostels_search_vector_update();`);
    await queryRunner.query(`DROP INDEX IF EXISTS idx_hostels_search_vector;`);
    await queryRunner.query(`ALTER TABLE hostels DROP COLUMN IF EXISTS search_vector;`);
  }
}
