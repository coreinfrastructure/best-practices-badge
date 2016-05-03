# Fix from https://github.com/activerecord-hackery/ransack/issues/518#issuecomment-186203333
# rubocop:disable Style/ClassAndModuleChildren
module SimpleForm::ActionViewExtensions::FormHelper
  alias original_simple_form_for simple_form_for

  def simple_form_for(record, options = {}, &block)
    if record.instance_of?(Ransack::Search) && !options.key?(:as)
      options[:as] = :q
    end

    original_simple_form_for(record, options, &block)
  end
end
