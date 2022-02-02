[v#.#.#] ([month] [YYYY])
  - [future tense verb] [feature]
  - Upgraded gems:
    - [gem]
  - Bugs fixes:
    - [future tense verb] [bug fix]
    - Fixes missing parent nodes during template and package imports
    - Fixes missing nodes for attachments during template and package imports
    - Bug tracker items:
      - [item]
  - Security Fixes:
    - High: (Authenticated|Unauthenticated) (admin|author|contributor) [vulnerability description]
    - Medium: (Authenticated|Unauthenticated) (admin|author|contributor) [vulnerability description]
    - Low: (Authenticated|Unauthenticated) (admin|author|contributor) [vulnerability description]

v4.1.2.1 (December 2021)
  - Security Fixes:
    - High: Authenticated author path traversal

v4.1.1 (November 2021)
  - Loosen dradis-plugins version requirement

v4.1.0 (November 2021)
  - No changes

v4.0.0 (July 2021)
  - No changes

v3.22.0 (April 2021)
  - No changes

v3.21.0 (February 2021)
  - No changes

v3.20.0 (January 2020)
  - Add views for the export view
  - Fix exporting projects with comments by deleted users

v3.19.0 (September 2020)
  - No changes

v3.18.0 (July 2020)
  - No changes

v3.17.0 (May 2020)
  - No changes

v3.16.0 (February 2020)
  - No changes

v3.15.0 (November 2019)
  - Being able to export/upload boards (v3)
  - Fix upload with attachments

v3.14.1 (October 2019)
  - Fix directory traversal vulnerability

v3.14.0 (August 2019)
  - No changes

v3.13.0 (June 2019)
  - No changes

v3.12.0 (March 2019)
  - No changes

v3.11.0 (November 2018)
  - Note and evidence comments in export/import

v3.10.0 (August 2018)
  - Check project existence for default user id
  - Issue comments in export/import
  - Replace Node methods that are now Project methods
  - Use project scopes

v3.9.0 (January 2018)
  - Add default user id as fallback for activity user when importing
  - Fix nodes upload

v3.8.0 (September 2017)
  - Add parse_report_content placeholders to import/export
  - Add version attribute to exported methodologies

v3.7.0 (July 2017)
  - Skip closing the logger in thorfile

v3.6.0 (March 2017)
  - Break down the #export and #parse methods into smaller tasks
  - Include file version in project template export
  - Make the project template exporter / uploader configurable
  - Stop using homegrown configuration and use `Rails.application.config`
