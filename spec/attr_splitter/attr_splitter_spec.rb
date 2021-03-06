require 'spec_helper'

class User < SuperModel::Base
  include ActiveModel::MassAssignmentSecurity
  extend AttrSplitter::ModelAdditions
  
  attr_splitter :phone_number, prefixes: [:first, :second, :third]
  attr_splitter :home_phone, suffixes: [:area_code, :first_three, :last_four]
  
  attr_accessor :phone_number, :home_phone
end

describe AttrSplitter::ModelAdditions do  
  it "combines prefixed attributes on create" do
    u = User.create!(first_phone_number: "415", second_phone_number: "555", third_phone_number: "9999")
    u.phone_number.should eq("4155559999")
  end
  
  it "combines suffixed attributes on create" do
    u = User.new
    u = User.create!(home_phone_area_code: "415", home_phone_first_three: "555", home_phone_last_four: "9999")
    u.home_phone.should eq("4155559999")
  end
  
  
  it "combines suffixed attributes on update" do
    u = User.create!
    u.home_phone_area_code = "415"
    u.home_phone_first_three = "555"
    u.home_phone_last_four = "9999"
    u.home_phone_dirty.should be_true
    u.save!
    u.home_phone.should eq("4155559999")
  end
  
  it "does not combine prefixed attributes if they are unchanged" do
    u = User.create!(first_phone_number: "415", second_phone_number: "555", third_phone_number: "9999")
    u.phone_number.should eq("4155559999")
    u.home_phone_area_code = "222"
    u.home_phone_first_three = "222"
    u.home_phone_last_four = "8888"
    u.home_phone_dirty.should be_true
    u.save!
    u.phone_number.should eq("4155559999")
  end
end

describe AttrSplitter::FormBuilderAdditions do  
  describe "with prefixed output" do
    describe "without any options" do
      it "should output three prefixed fields" do
        template = ActionView::Base.new
        template.output_buffer = ""
        builder = ActionView::Helpers::FormBuilder.new(:user, 
          User.new, 
          template, 
          {}, 
          proc { })
        output = builder.multi_text_field(:phone_number, prefixes: { first: 3, second: 3, third: 4 })
        output.should include(%q{<input id="user_first_phone_number" maxlength="3" name="user[first_phone_number]" style="width: 1.875em; margin-right: 5px;" type="text" />})
        output.should include(%q{<input id="user_second_phone_number" maxlength="3" name="user[second_phone_number]" style="width: 1.875em; margin-right: 5px;" type="text" />})
        output.should include(%q{<input id="user_third_phone_number" maxlength="4" name="user[third_phone_number]" style="width: 2.5em; margin-right: 5px;" type="text" />})
      end
    end
    
    describe "with jump" do
      it "should output three prefixed fields with jump javascript" do
        template = ActionView::Base.new
        template.output_buffer = ""
        builder = ActionView::Helpers::FormBuilder.new(:user, 
          User.new, 
          template, 
          {}, 
          proc { })
        output = builder.multi_text_field(:phone_number, prefixes: { first: 3, second: 3, third: 4 }, include_jump: true)
        output.should include(%q{<input id="user_first_phone_number" maxlength="3" name="user[first_phone_number]" onkeyup="if(this.value.length == this.maxLength){ document.getElementById(&#x27;user_second_phone_number&#x27;).focus();}" style="width: 1.875em; margin-right: 5px;" type="text" />})
        output.should include(%q{<input id="user_second_phone_number" maxlength="3" name="user[second_phone_number]" onkeyup="if(this.value.length == this.maxLength){ document.getElementById(&#x27;user_third_phone_number&#x27;).focus();}" style="width: 1.875em; margin-right: 5px;" type="text" />})
        output.should include(%q{<input id="user_third_phone_number" maxlength="4" name="user[third_phone_number]" style="width: 2.5em; margin-right: 5px;" type="text" />})
      end
    end
    
    describe "with obscured text" do
      it "should output three prefixed fields with onblur and onfocus" do
        template = ActionView::Base.new
        template.output_buffer = ""
        builder = ActionView::Helpers::FormBuilder.new(:user, 
          User.new, 
          template, 
          {}, 
          proc { })
        output = builder.multi_text_field(:phone_number, prefixes: { first: 3, second: 3, third: 4 }, obscure_text: true)
        output.should include(%q{<input id="user_first_phone_number" maxlength="3" name="user[first_phone_number]" onblur="if(this.value.length == this.maxLength){ this.type = &#x27;password&#x27;; }" onfocus="this.type = &#x27;text&#x27;;" style="width: 1.875em; margin-right: 5px;" type="password" />})
        output.should include(%q{<input id="user_second_phone_number" maxlength="3" name="user[second_phone_number]" onblur="if(this.value.length == this.maxLength){ this.type = &#x27;password&#x27;; }" onfocus="this.type = &#x27;text&#x27;;" style="width: 1.875em; margin-right: 5px;" type="password" />})
        output.should include(%q{<input id="user_third_phone_number" maxlength="4" name="user[third_phone_number]" onblur="if(this.value.length == this.maxLength){ this.type = &#x27;password&#x27;; }" onfocus="this.type = &#x27;text&#x27;;" style="width: 2.5em; margin-right: 5px;" type="password" />})
      end
    end
  end
  
  describe "with suffixed output" do
    it "should output three suffixed fields" do
      template = ActionView::Base.new
      template.output_buffer = ""
      builder = ActionView::Helpers::FormBuilder.new(:user, 
        User.new, 
        template, 
        {}, 
        proc { })
      output = builder.multi_text_field(:home_phone, suffixes: { area_code: 3, first_three: 3, last_four: 4 })
      output.should include(%q{<input id="user_home_phone_area_code" maxlength="3" name="user[home_phone_area_code]" style="width: 1.875em; margin-right: 5px;" type="text" />})
      output.should include(%q{<input id="user_home_phone_first_three" maxlength="3" name="user[home_phone_first_three]" style="width: 1.875em; margin-right: 5px;" type="text" />})
      output.should include(%q{<input id="user_home_phone_last_four" maxlength="4" name="user[home_phone_last_four]" style="width: 2.5em; margin-right: 5px;" type="text" />})
    end
  end
end
  