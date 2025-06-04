# Oracle DB Scripts

This project contains a collection of Perl scripts designed to interact with an Oracle database. These scripts provide functionalities for database object definition retrieval and dictionary searching.

## `get_object_definition.pl`

This script retrieves the Data Definition Language (DDL) for a specified Oracle database object. It can be used to get the DDL for tables, views, procedures, functions, packages, synonyms, users, tablespaces, etc.

### Usage

```bash
./get_object_definition.pl <object_owner>.<object_name> <object_type>
./get_object_definition.pl <tablespace_name> TABLESPACE
./get_object_definition.pl <username> USER
```

**Arguments:**

*   `<object_owner>.<object_name>`: The owner and name of the database object (e.g., `SCOTT.EMP`).
*   `<object_type>`: The type of the database object (e.g., `TABLE`, `VIEW`, `PROCEDURE`).
*   `<tablespace_name>`: The name of the tablespace when using the `TABLESPACE` option.
*   `<username>`: The name of the user when using the `USER` option.

**Options:**

*   `-h`, `-help`: Display the help message.

### Example

To get the DDL for the `EMP` table owned by `SCOTT`:

```bash
./get_object_definition.pl SCOTT.EMP TABLE
```
## `search_in_dictionary.pl`

This script searches the Oracle data dictionary for objects matching a given pattern. It displays information about the found objects, including their owner, name, type, status, creation date, and last DDL modification time.

### Usage

```bash
./search_in_dictionary.pl <pattern>
```

**Arguments:**

*   `<pattern>`: The search pattern to look for in object names. The pattern can include SQL `LIKE` wildcards (e.g., `%`, `_`).

**Options:**

*   `-h`, `-help`: Display the help message.

### Example

To search for all objects whose names contain "USER":

```bash
./search_in_dictionary.pl %USER%
```
## Prerequisites

*   **Perl:** The scripts are written in Perl and require a Perl interpreter to be installed on your system.
*   **Oracle Client:** You need to have an Oracle database client installed and configured (specifically `sqlplus`) to allow the scripts to connect to an Oracle database.
*   **Database Privileges:** The database user connecting via `sqlplus` (implicitly `/ as sysdba` in the scripts) needs appropriate privileges to access `DBA_OBJECTS`, `DBA_SYNONYMS`, and `DBMS_METADATA` packages.

## Usage

1.  **Ensure Prerequisites:** Make sure you have Perl and Oracle Client (`sqlplus`) installed and configured correctly, and that the necessary database privileges are granted.
2.  **Download Scripts:** Place the `.pl` script files in your desired directory.
3.  **Set Permissions:** Make the scripts executable:
    ```bash
    chmod +x get_object_definition.pl
    chmod +x search_in_dictionary.pl
    ```
4.  **Run Scripts:** Execute the scripts from the command line as described in their respective sections above. The scripts connect to the Oracle database as `sysdba` using operating system authentication (`/ as sysdba`). Ensure your environment is set up to allow this, or modify the connection string within the scripts if needed.

    For example, to use `get_object_definition.pl`:
    ```bash
    ./get_object_definition.pl SCOTT.EMP TABLE
    ```

    To use `search_in_dictionary.pl`:
    ```bash
    ./search_in_dictionary.pl %AUDIT%
    ```
