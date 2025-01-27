require "spec_helper"

RSpec.describe "Facet" do
  describe "#from_finder_admin_form_params" do
    it "builds a facet for a finder schema" do
      params = {
        "key" => "foo",
        "name" => "Foo",
        "short_name" => "f",
        "type" => "text",
        "preposition" => "sector",
        "display_as_result_metadata" => "false",
        "filterable" => "true",
        "allowed_values" => "existing value {existing-value}\nnew value",
      }
      facet = Facet.from_finder_admin_form_params(params)
      expect(facet.key).to eq("foo")
      expect(facet.name).to eq("Foo")
      expect(facet.short_name).to eq("f")
      expect(facet.type).to eq("text")
      expect(facet.preposition).to eq("sector")
      expect(facet.display_as_result_metadata).to eq(false)
      expect(facet.filterable).to eq(true)
    end

    it "derives the key from the name if no key provided" do
      params = { "name" => "Foo Bar Baz" }
      facet = Facet.from_finder_admin_form_params(params)
      expect(facet.key).to eq("foo_bar_baz")
    end

    it "returns nil for 'short_name' if not provided/blank" do
      facet = Facet.from_finder_admin_form_params({ "short_name" => "" })
      expect(facet.short_name).to eq(nil)
    end

    it "returns nil for 'preposition' if not provided/blank" do
      facet = Facet.from_finder_admin_form_params({ "preposition" => "" })
      expect(facet.preposition).to eq(nil)
    end

    describe "inferring the boolean value, or absence of a value, for 'display_as_result_metadata' and 'filterable'" do
      it "converts 'true' to true for 'display_as_result_metadata'" do
        facet = Facet.from_finder_admin_form_params({ "display_as_result_metadata" => "true" })
        expect(facet.display_as_result_metadata).to eq(true)
      end

      it "converts 'false' to false for 'display_as_result_metadata'" do
        facet = Facet.from_finder_admin_form_params({ "display_as_result_metadata" => "false" })
        expect(facet.display_as_result_metadata).to eq(false)
      end

      it "sets 'display_as_result_metadata' to 'nil' for any other values" do
        facet = Facet.from_finder_admin_form_params({ "display_as_result_metadata" => "" })
        expect(facet.display_as_result_metadata).to eq(nil)
      end

      it "converts 'true' to true for 'filterable'" do
        facet = Facet.from_finder_admin_form_params({ "filterable" => "true" })
        expect(facet.filterable).to eq(true)
      end

      it "converts 'false' to false for 'filterable'" do
        facet = Facet.from_finder_admin_form_params({ "filterable" => "false" })
        expect(facet.filterable).to eq(false)
      end

      it "sets 'filterable' to 'nil' for any other values" do
        facet = Facet.from_finder_admin_form_params({ "filterable" => "" })
        expect(facet.filterable).to eq(nil)
      end
    end

    describe "constructing the allowed_values" do
      it "uses any pre-supplied keys in curly brackets" do
        params = { "type" => "enum_text_multiple", "allowed_values" => "Foo {food}\nBart {bar}" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq([
          { label: "Foo", value: "food" },
          { label: "Bart", value: "bar" },
        ])
      end

      it "also works for the enum_text_single 'type'" do
        params = { "type" => "enum_text_single", "allowed_values" => "Foo {food}\nBart {bar}" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq([
          { label: "Foo", value: "food" },
          { label: "Bart", value: "bar" },
        ])
      end

      it "derives the key, in kebab-case, from the label if no key provided" do
        params = { "type" => "enum_text_multiple", "allowed_values" => "Foo\nSome Long Name" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq([
          { label: "Foo", value: "foo" },
          { label: "Some Long Name", value: "some-long-name" },
        ])
      end

      it "strips any extraneous spaces" do
        params = { "type" => "enum_text_multiple", "allowed_values" => "Foo     { bar  }" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq([
          { label: "Foo", value: "bar" },
        ])
      end

      it "returns empty array if no values provided" do
        params = { "type" => "enum_text_multiple", "allowed_values" => "" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq([])
      end

      it "returns nil if not of an enum type, even if allowed_values have been specified" do
        params = { "type" => "text", "allowed_values" => "foo {foo}\nbar" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq(nil)

        params = { "type" => "date", "allowed_values" => "foo {foo}\nbar" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.allowed_values).to eq(nil)
      end
    end

    describe "converting the facet 'type' and setting the corresponding specialist_publisher_properties" do
      it "converts 'enum_text_multiple' type to 'text', and sets specialist_publisher_properties to select multiple" do
        params = { "type" => "enum_text_multiple" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.type).to eq("text")
        expect(facet.specialist_publisher_properties).to eq({ select: "multiple" })
      end

      it "converts 'enum_text_single' type to 'text', and sets specialist_publisher_properties to select one" do
        params = { "type" => "enum_text_single" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.type).to eq("text")
        expect(facet.specialist_publisher_properties).to eq({ select: "one" })
      end

      it "leaves type 'text' as-is, and sets specialist_publisher_properties to nil" do
        params = { "type" => "text" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.type).to eq("text")
        expect(facet.specialist_publisher_properties).to eq(nil)
      end

      it "leaves type 'date' as-is, and sets specialist_publisher_properties to nil" do
        params = { "type" => "date" }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.type).to eq("date")
        expect(facet.specialist_publisher_properties).to eq(nil)
      end

      it "adds presence validations to the specialist_publisher_properties if type is text" do
        params = { "type" => "enum_text_single", "validations" => %w[required] }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.type).to eq("text")
        expect(facet.specialist_publisher_properties).to eq({ select: "one", validations: { required: {} } })
      end

      it "adds presence validations to the specialist_publisher_properties if type is date" do
        params = { "type" => "date", "validations" => %w[required] }
        facet = Facet.from_finder_admin_form_params(params)
        expect(facet.type).to eq("date")
        expect(facet.specialist_publisher_properties).to eq({ validations: { required: {} } })
      end
    end
  end

  describe "#to_finder_schema_attributes" do
    it "transforms the attributes of the facet to a hash of finder schema attributes" do
      facet = Facet.new
      facet.key = "foo"
      facet.name = "Foo"
      facet.short_name = "f"
      facet.type = "text"
      facet.preposition = "sector"
      facet.display_as_result_metadata = false
      facet.filterable = true
      facet.allowed_values = [
        { label: "existing value", value: "existing-value" },
        { label: "new value", value: "new-value" },
      ]
      facet.specialist_publisher_properties = { select: "one" }

      expect(facet.to_finder_schema_attributes).to eq({
        key: "foo",
        name: "Foo",
        short_name: "f",
        type: "text",
        preposition: "sector",
        display_as_result_metadata: false,
        filterable: true,
        allowed_values: [
          { label: "existing value", value: "existing-value" },
          { label: "new value", value: "new-value" },
        ],
        specialist_publisher_properties: { select: "one" },
      })
    end

    it "omits any nil values from the hash" do
      facet = Facet.new
      facet.key = "foo"
      facet.name = "Foo"
      facet.type = "text"

      expect(facet.to_finder_schema_attributes).to eq({
        key: "foo",
        name: "Foo",
        type: "text",
      })
    end

    it "returns the hash keys in a specific order (to minimise the eventual diff)" do
      facet = Facet.new
      facet.key = "foo"
      facet.name = "Foo"
      facet.short_name = "f"
      facet.type = "text"
      facet.preposition = "sector"
      facet.display_as_result_metadata = false
      facet.filterable = true
      facet.allowed_values = [
        { label: "existing value", value: "existing-value" },
        { label: "new value", value: "new-value" },
      ]
      facet.specialist_publisher_properties = { select: "one" }

      expect(facet.to_finder_schema_attributes.keys).to eq(%i[
        allowed_values
        display_as_result_metadata
        filterable
        key
        name
        preposition
        specialist_publisher_properties
        short_name
        type
      ])
    end
  end
end
