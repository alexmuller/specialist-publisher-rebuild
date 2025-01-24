# Creating, editing and removing specialist document types and finders

To create or edit a new specialist document you will have to make changes to this
application, [publishing-api][publishing-api] and [search-api][search-api]. You will not have to make any changes to frontend
applications.

**IMPORTANT**

Recent changes to Specialist Publisher now allow users to self-serve. These requests will be coming through Zendesk, as a code diff for the [specialist-publisher][specialist-publisher] repo. Follow the steps below to validate the thoroughness of the changes and open the remaining PRs against [publishing-api][publishing-api] and [search-api][search-api], if needed.

[publishing-api]: https://github.com/alphagov/publishing-api
[search-api]: https://github.com/alphagov/search-api
[specialist-publisher]: https://github.com/alphagov/specialist-publisher

# __Creating__ a specialist document type

## 1. Add a schema to Publishing API
See [example PR here](https://github.com/alphagov/publishing-api/pull/3026/files).

1. Add the format to [allowed document types list](https://github.com/alphagov/publishing-api/blob/main/content_schemas/allowed_document_types.yml).
2. Add any new field definitions to [this file](https://github.com/alphagov/publishing-api/blob/main/content_schemas/formats/shared/definitions/_specialist_document.jsonnet).
3. Run `bundle exec rake build_schemas` to regenerate schemas.

When the PR is reviewed and its tests passing, it can be merged and deployed at this point.

## 2. Create a new specialist document format in Specialist Publisher

### Create the schema

See [CMA cases](https://github.com/alphagov/specialist-publisher/blob/main/lib/documents/schemas/cma_cases.json).

New formats should be added with `target_stack: "draft"` so that departments can preview the finder before you publish it.

You'll need to generate your own UUIDs for the `content_id` (of the finder), and the `signup_content_id` fields:

   ```
   $ irb
   irb(main):001:0> require "securerandom"
   => true
   irb(main):002:0> SecureRandom.uuid
   => "5087e8b6-ee54-40f9-b592-8c2813c7037d"
   ```
For a breakdown of email subscription options see [Configure the email sign up page](#4-configure-the-email-sign-up-page).

### Create the model

Include any required validations, tests and factories.

See [CMA cases](https://github.com/alphagov/specialist-publisher/blob/main/app/models/cma_case.rb).

### Create the view template

Create a view file in the [views folder](https://github.com/alphagov/specialist-publisher/tree/main/app/views/metadata_fields). See [CMA cases example](https://github.com/alphagov/specialist-publisher/blob/main/app/views/metadata_fields/_cma_cases.html.erb).

Whilst a handful of legacy finders still use a custom view, all new finders should be referencing the [shared template](https://github.com/alphagov/specialist-publisher/blob/main/app/views/shared/_specialist_document_form.html.erb), which determines which form fields to display based on the finder schema.

NB: The select type of an input (one/multiple) is now configured under the `specialist_publisher_properties` [in the schema](https://github.com/alphagov/specialist-publisher/blob/36170eb7841fc4acaad77603f3e55e0a80122a74/lib/documents/schemas/algorithmic_transparency_records.json#L151).

## 3. Configure Search API

Search API needs copies of the schema very similar to the one in Specialist Publisher. See:

- [CMA case schema](https://github.com/alphagov/search-api/blob/main/config/schema/elasticsearch_types/cma_case.json) (example)
- [field definitions](https://github.com/alphagov/search-api/blob/main/config/schema/field_definitions.json)

You'll also need to add your document format to:

- the main ES types list [govuk.json](https://github.com/alphagov/search-api/blob/main/config/schema/indexes/govuk.json)
- [migrated_formats.yaml](https://github.com/alphagov/search-api/blob/main/config/govuk_index/migrated_formats.yaml)
- [mapped_document_types.yaml](https://github.com/alphagov/search-api/blob/main/config/govuk_index/mapped_document_types.yaml)

Finally, you'll need to add your custom fields to:

- [elasticsearch_presenter.rb](https://github.com/alphagov/search-api/blob/main/lib/govuk_index/presenters/elasticsearch_presenter.rb)
- [specialist_presenter.rb](https://github.com/alphagov/search-api/blob/main/lib/govuk_index/presenters/specialist_presenter.rb)

## 4. Configure the email sign up page

The email sign up page is rendered by [Finder Frontend](https://github.com/alphagov/finder-frontend) using the schema configuration in specialist publisher.

The finder default is to have no email subscription. Email subscriptions can be set as:

### 1. Subscribe to all fields

- Configure `signup_content_id` - a new `UUID` for the email signup page. Whilst this is enough to configure email subscription, it does not offer the user any filtering options.
- You can allow the user to preserve their facet selection when navigating to the email subscription page. In the `email_filter_options` hash, set `email_filter_by` to `all_selected_facets`. This will pick up all the facets that have `allowed_values` and `filterable: true`. See [example](https://github.com/alphagov/specialist-publisher/blob/91ee849549c5e5478126d06842513a516cacceb2/lib/documents/schemas/marine_equipment_approved_recommendations.json#L12).
- You may exclude some of the facets by additionally setting `all_selected_facets_except_for` - see [example](https://github.com/alphagov/specialist-publisher/blob/91ee849549c5e5478126d06842513a516cacceb2/lib/documents/schemas/export_health_certificates.json#L8).
- Set `subscription_list_title_prefix` (optional).

### 2. Subscribe to specific fields(set)

- Configure the `signup_content_id` and, optionally, the `subscription_list_title_prefix`, as in the previous step.
- Set `email_filter_by` to a specific facet - see [example](https://github.com/alphagov/specialist-publisher/blob/91ee849549c5e5478126d06842513a516cacceb2/lib/documents/schemas/tax_tribunal_decisions.json#L13).
- Edit [email-alert-api](https://github.com/alphagov/email-alert-api/tree/main/lib) by adding the new filters to [valid_tags.rb](https://github.com/alphagov/email-alert-api/blob/main/lib/valid_tags.rb).

#### Breakdown of the email options:
- `subscription_list_title_prefix` - typically set in most finders. It defines the beginning of the email title. For example, CMA cases have this value set to `CMA cases`, meaning an email title would read as "_CMA cases_ with digital markets unit". When omitted, the email title will only reference subscribed facets.
- `email_alert_topic_name_overrides` - changes the display label of individual facets options in the email title the user receives upon subscribing.
- `downcase_email_alert_topic_names` - downcases the display label of individual facet options in the email title the user receives upon subscribing.
- `pre_checked_email_alert_checkboxes` - takes an array of facets, which will appear pre-checked on the email signup page.


### 3. Signup link

If the subscription is managed by an external service, it should be set via a `signup_link`. See [example](https://github.com/alphagov/specialist-publisher/blob/91ee849549c5e5478126d06842513a516cacceb2/lib/documents/schemas/drug_safety_updates.json#L148).


## 5. Deploy a finder to the draft stack (for previewing)

To deploy a new finder for previewing:
   1. Ensure the finder `target_stack` is set to `draft`
   2. [Deploy the finder](#7-deploy-a-finder) to draft stack
   3. Wait for department's feedback and approval and agree on a release date

NB: Depending on the finder requirements, you may choose to allow the users to publish documents in preview mode, which 
would enable them to test the full finder filtering functionality. Changes to the schema requested after documents have been
published, could require running a reindex, and there is a risk of loss of data. In order to prevent users from publishing,
we could give only basic Signon permissions whilst in preview mode. Signon access to the Specialist Publisher app, only 
gives the user writer access (they may create, edit, and update, but not publish or unpublish).

## 6. Publish a finder to the live stack

To release the finder to the live stack:
   1. Open a new PR changing the `target_stack` of the finder from `draft` to `live` in Specialist Publisher json schema config
   2. [Deploy the finder](#7-deploy-a-finder) to the live stack


## 7. Deploy a finder
1. Merge and deploy Publishing API, Specialist Publisher and Search API, if changed.
   - Ensure you deploy Publishing API first, to avoid schema validation errors.
2. Also deploy Email Alert API if you have made changes to it.
3. Run `rake SEARCH_INDEX=govuk 'search:update_schema'` on Search API if you have made changes. 
   - This command will likely succeed for a newly created finder with no published documents, or when adding new fields and values. 
   - When making structural changes to finders, such as changing a field's type, this command might error and you will have to do a [full reindex](https://docs.publishing.service.gov.uk/manual/reindex-elasticsearch.html#how-to-reindex-an-elasticsearch-index).
   - A full reindex takes around 30-45 minutes on Production, or 3-4 hours on Integration.
4. Publish the finder by running the rake task `publishing_api:publish_finders` or `publishing_api:publish_finder[your_format_name_based_on_the_schema_file]` against the specialist publisher app (rake tasks [here](https://github.com/alphagov/specialist-publisher/blob/ce68fdb008cab05225e0493e19decba5365e1e20/lib/tasks/publishing_api.rake)).


## 8. Permissions

Specialist Publisher grants access to the publishing interface for a document type to the following Signon users:

1. Users that belong to the owner organisation - have default "write" permissions, allowing them to view and draft new documents. 
2. Users that belong to the owner organisation AND have `editor` permission in Signon - are considered "departmental editors" and can publish, unpublish and discard documents.
3. Users that have the permission `<your_new_document_type>_editor` in Signon are granted "departmental editor" access regardless of their organisation. This is sometimes required for cross-departmental documents. These special permissions need to be [created manually](https://docs.publishing.service.gov.uk/repos/signon/usage.html#creating-editing-and-deleting-permissions) in Signon. You do not need to create this permission unless cross-departmental access has been explicitly requested.

You'll need to manually grant users access to the Specialist Publisher app in Signon, and the `editor` permission (or custom cross-organisation permissions from step 3 above) if appropriate.

# __Editing__ a specialist document type

We often receive requests to add new fields to a specialist document or to add new values to existing fields.

## Adding a new field to an existing specialist document

1. In `publishing-api`:
   - Add the new field in the [specialist_document schema](https://github.com/alphagov/publishing-api/blob/6d5595470bd0e7f3072e06f0113e3ca5514b6e98/content_schemas/formats/shared/definitions/_specialist_document.jsonnet). See [example commit](https://github.com/alphagov/publishing-api/pull/2968/commits/b7d9cd1f6bb5d8d08fda7b6e219b2467134406c4).
   - Run `bundle exec rake build_schemas` to regenerate schemas after adding the new value(s).

2. In `specialist publisher`:
   - Add the new field to the relevant [model](https://github.com/alphagov/specialist-publisher/tree/main/app/models), including any required validations, tests and factories.
   - Add fields to relevant [schema](https://github.com/alphagov/specialist-publisher/tree/main/lib/documents/schemas) files.
   - For legacy finders that don't use the shared view, you may need to update the [view](https://github.com/alphagov/specialist-publisher/tree/main/app/views/metadata_fields).

<!-- TODO: Update these with up-to-date examples that don't include any view or 'expanded field' changes-->
   See [this](https://github.com/alphagov/specialist-publisher/pull/2847/commits/37fee332a721222c392f541a7f3b747d5d7a8c27) commit for an example.

3. In `search-api`, add the new field in the following places (see [this](https://github.com/alphagov/search-api/pull/3043/commits/12eee8d6bab4e7606b4014684907f60574e713ba) commit for an example):
   - the relevant schema in the [elasticsearch_types ](https://github.com/alphagov/search-api/tree/main/config/schema/elasticsearch_types)directory.
   - the [elasticsearch_presenter](https://github.com/alphagov/search-api/blob/main/lib/govuk_index/presenters/elasticsearch_presenter.rb).
   - the [specialist_presenter](https://github.com/alphagov/search-api/blob/main/lib/govuk_index/presenters/specialist_presenter.rb).
   - the [field_definitions](https://github.com/alphagov/search-api/blob/main/config/schema/field_definitions.json) file.

4. [Republish the finder](#7-deploy-a-finder)

## Removing a field from an existing specialist document

NB: In order to remove a field, ensure no document are tagged with that field, or that the finder's owners are aware of the data loss implications.

1. In `publishing-api`:
    - Remove the field from the [specialist_document schema](https://github.com/alphagov/publishing-api/blob/6d5595470bd0e7f3072e06f0113e3ca5514b6e98/content_schemas/formats/shared/definitions/_specialist_document.jsonnet). 
    - Run `bundle exec rake build_schemas` to regenerate schemas after removing the new value(s).
   
   See removal of `key_reference` in [example commit](https://github.com/alphagov/publishing-api/pull/3075/commits/03197cc43f11b762314a17ecbc37ec9601c0ede9).

2. In `specialist publisher`:
    - Remove field from [model](https://github.com/alphagov/specialist-publisher/tree/main/app/models).
    - Remove field usage from [view](https://github.com/alphagov/specialist-publisher/tree/main/app/views/metadata_fields) (if this is a legacy finder that isn't referring to the shared view).
    - Remove field from [schema](https://github.com/alphagov/specialist-publisher/tree/main/lib/documents/schemas) files.
    - Remove any other usages, such as from tests and factories.
   
   See removal of `key_reference` in [example commit](https://github.com/alphagov/specialist-publisher/pull/2942/commits/6b215cb8d02fdcee6d6e05d108f7e2cffca091c4).

3. In `search-api`, remove the field from:
    - The relevant schema in the [elasticsearch_types ](https://github.com/alphagov/search-api/tree/main/config/schema/elasticsearch_types)directory.
    - The [elasticsearch_presenter](https://github.com/alphagov/search-api/blob/main/lib/govuk_index/presenters/elasticsearch_presenter.rb).
    - The [specialist_presenter](https://github.com/alphagov/search-api/blob/main/lib/govuk_index/presenters/specialist_presenter.rb).
    - The [field_definitions](https://github.com/alphagov/search-api/blob/main/config/schema/field_definitions.json) file.
   
   See removal of `key_reference` in [example commit](https://github.com/alphagov/search-api/pull/3120/commits/b18f25ce86f496e46294ebce6e37e42bf035c105).

4. [Republish the finder](#7-deploy-a-finder)

## Adding values for existing fields on a specialist document
Specific values for fields of type array are now defined only in the `specialist_publisher` app. To add a value:
1. In `specialist publisher`, add the new values to the relevant file in the [schema](https://github.com/alphagov/specialist-publisher/tree/main/lib/documents/schemas) directory. See [this](https://github.com/alphagov/specialist-publisher/pull/2958/commits/930b4c82928a616cc848d1e759cf31b521771b15) commit for an example.
2. Deploy Specialist Publisher.
3. Publish the finder by running the rake task `publishing_api:publish_finders` or `publishing_api:publish_finder[your_format_name_based_on_the_schema_file]` against the specialist publisher app (rake tasks [here](https://github.com/alphagov/specialist-publisher/blob/ce68fdb008cab05225e0493e19decba5365e1e20/lib/tasks/publishing_api.rake)).

## Removing values for existing fields on a specialist document

NB: In order to remove a field value, ensure no document are tagged with that value, or that the finder's owners are aware of the data loss implications.

Specific values for fields of type array are now defined only in the `specialist_publisher` app. To remove a value:
1. In `specialist publisher`, remove the value entry from the `allowed_values` array of the relevant field, from the corresponding json file in the [schema](https://github.com/alphagov/specialist-publisher/tree/main/lib/documents/schemas) directory.
2. Deploy Specialist Publisher.
3. Publish the finder by running the rake task `publishing_api:publish_finders` or `publishing_api:publish_finder[your_format_name_based_on_the_schema_file]` against the specialist publisher app (rake tasks [here](https://github.com/alphagov/specialist-publisher/blob/ce68fdb008cab05225e0493e19decba5365e1e20/lib/tasks/publishing_api.rake)).


# __Editing__ a specialist finder

The [schema](https://github.com/alphagov/specialist-publisher/tree/main/lib/documents/schemas) files that define a specialist document, are also used to configure that document's specialist finder. See [this](https://github.com/alphagov/specialist-publisher/pull/1899/commits/925abc689119138a0e04e17d3610f8ae276773dd) commit for an example.

# __Unpublishing__ a specialist finder

**Important**: In order to remove a finder, you should ensure there is a clear business requirement in doing so, and that all associated documents have been correctly dealt with - unpublished, redirected, migrated or removed.
If the code is not removed from all relevant repositories, there is a chance the finder will be inadvertently republished, for example by republishing all finders. You must therefore make sure the code is removed in order to keep the finder unpublished.

The following steps are required to remove a finder:
1. Unpublish the finder in all environments using the provided rake task:
   ```
   rake unpublish:redirect_finder["uk_market_conformity_assessment_bodies","https://redirection_link.gov.uk"]
   ```
2. Remove usages from `publishing-api`:
   - Remove the format from [allowed document types list](https://github.com/alphagov/publishing-api/blob/main/content_schemas/allowed_document_types.yml).
   - Remove the field definitions from [this file](https://github.com/alphagov/publishing-api/blob/main/content_schemas/formats/shared/definitions/_specialist_document.jsonnet).
   - If present, remove the example from [this directory](https://github.com/alphagov/publishing-api/tree/main/content_schemas/examples/specialist_document/frontend).
   - Run `bundle exec rake build_schemas` to regenerate schemas.
   
   See [example commit](https://github.com/alphagov/publishing-api/pull/2706).

3. Remove usages from `specialist publisher`. See [example commit](https://github.com/alphagov/specialist-publisher/pull/2588/files).
4. Remove usages from `search-api`. See [example commit](https://github.com/alphagov/search-api/pull/2881/files).
5. Remove any usages from `finder-frontend`, if applicable.
6. Deploy all changes.
