require 'spec_helper'
describe Upsert do
  describe "is just as correct as other ways" do
    describe 'compared to native ActiveRecord' do
      it "is as correct as than new/set/save" do
        assert_same_result lotsa_records do |records|
          records.each do |selector, document|
            if pet = Pet.where(selector).first
              pet.update_attributes document, :without_protection => true
            else
              pet = Pet.new
              selector.each do |k, v|
                pet.send "#{k}=", v
              end
              document.each do |k, v|
                pet.send "#{k}=", v
              end
              pet.save!
            end
          end
        end
      end
      it "is as correct as than find_or_create + update_attributes" do
        assert_same_result lotsa_records do |records|
          dynamic_method = nil
          records.each do |selector, document|
            dynamic_method ||= "find_or_create_by_#{selector.keys.join('_or_')}"
            pet = Pet.send(dynamic_method, *selector.values)
            pet.update_attributes document, :without_protection => true
          end
        end
      end
      it "is as correct as than create + rescue/find/update" do
        assert_same_result lotsa_records do |records|
          dynamic_method = nil
          records.each do |selector, document|
            dynamic_method ||= "find_or_create_by_#{selector.keys.join('_or_')}"
            begin
              Pet.create selector.merge(document), :without_protection => true
            rescue
              pet = Pet.send(dynamic_method, *selector.values)
              pet.update_attributes document, :without_protection => true
            end
          end
        end
      end
    end
    describe 'compared to activerecord-import' do
      it "is as correct as faking upserts with activerecord-import" do
        unless Pet.supports_on_duplicate_key_update?
          raise "#{Pet.connection} does not support activerecord-import's :on_duplicate_key_update"
        end
        assert_same_result lotsa_records do |records|
          columns = nil
          all_values = []
          records.each do |selector, document|
            columns ||= (selector.keys + document.keys).uniq
            all_values << columns.map do |k|
              if document.has_key?(k)
                # prefer the document so that you can change rows
                document[k]
              else
                selector[k]
              end
            end
          end
          Pet.import columns, all_values, :timestamps => false, :on_duplicate_key_update => columns
        end
      end
    end
  end
end