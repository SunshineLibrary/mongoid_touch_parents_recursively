mongoid_touch_parents_recursively
=================================

touch parents recursively in Mongoid

Install
--------------------------------
gem 'mongoid_touch_parents_recursively'

Usage
--------------------------------

```ruby
# 配置最公用的Mongoid::Sunshine
module Mongoid
  module Sunshine
    extend ActiveSupport::Concern
    included do
      include Mongoid::Document
      include Mongoid::Timestamps
      include Mongoid::TouchParentsRecursively
    end
  end
end

# 配置需要touch的父级
::Mongoid::TouchParentsRecursively.allowed_models_proc = lambda do |model_name|
  [Subject, Folder, FolderClassroom, FolderPiece, Piece].map(&:to_s).include? model_name
end

```
