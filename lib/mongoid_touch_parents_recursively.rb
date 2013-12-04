# encoding: UTF-8
# TODO 需要修改relations等，才能改为ActiveModel公用

require 'mongoid'

module ::Mongoid
  module TouchParentsRecursively
    extend ActiveSupport::Concern

    # 设置是否忽略某些model
    mattr_accessor :allowed_models_proc
    self.allowed_models_proc = proc {|model| true }

    included do

      after_save :touch_parents_recursively
      def touch_parents_recursively
        # cache @__parents
        @__parents ||= begin
          __parents = Set.new

          # 按 @diyumoshushi 建议，CRUD需要通知到所有关联的父级对象，包括多对多，这样可以兼容被删除的情况。
          # @mvj3 但是只在第一级就可兼容多对多情况下被删除的情况。因为关联的第二级以上就没有被删除了。
          # 根本解决的是 **引用的问题**，去通知位于顶级的subject去更新。
          Utils.fetch_and_store_parent __parents, self, true
        end

        @__parents.each(&:touch)
      end
    end


    # put encapsulation method here
    module Utils
      def self.fetch_and_store_parent __parents, __parent, is_first_level
        # parents 可能的是 has_and_belongs_to_many or belongs_to
        Array(__parent).each do |__parent1| # compact with Mongoid::Relations::Targets::Enumerable as Enumerable
          __parent1.class.relations.select do |k, v|
            __result = false
            __result ||= (v.macro == :belongs_to)
            __result ||= (k.match(__parent1.class.name.singularize.downcase) && (v.macro != :embeds_many)) if is_first_level
            __result = false if not ::Mongoid::TouchParentsRecursively.allowed_models_proc.call(v.class_name)
            __result
          end.map do |k, v|
            Array(__parent1.send(k))
          end.flatten.each do |__parent2|
            if not __parents.include? __parent2
              __parents.add __parent2
              Utils.fetch_and_store_parent __parents, __parent2, false
            end
          end
        end

        return __parents
      end
    end

  end
end
