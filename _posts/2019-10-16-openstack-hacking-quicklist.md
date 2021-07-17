----

A few links for OpenStack hacking.

- [Creating release notes with `reno`](https://docs.openstack.org/reno/latest/user/usage.html)

## Using oslo.db

- Install oslo_db
- Create a pkg/db directory
  - add an api.py (just copy this from somewhere?)
  - add a migrate.py (?)
- Init alembic: alembic init pkg/db/sqlalchemy/alembic
  - change script_location to "%(here)s/alembic" and move to sqlalchemy folder
