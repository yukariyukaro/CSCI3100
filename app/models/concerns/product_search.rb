module ProductSearch
  extend ActiveSupport::Concern

  module ClassMethods
    def search(query, scope: all)
      return scope if query.blank?

      # Ensure advanced_search doesn't call back to search creating infinite loop
      return scope.advanced_search(query) if postgresql_search?

      basic_search(query, scope)
    end

    def suggest(query, scope: all)
      return [] if query.blank?

      pattern = "%#{sanitize_sql_like(query)}%"
      suggest_scope(scope, pattern).select(:name).distinct.limit(8).pluck(:name)
    end

    private

    def lower(arel_attr)
      Arel::Nodes::NamedFunction.new("LOWER", [arel_attr])
    end

    def basic_search(query, scope)
      like = like_pattern(query)
      fuzzy = fuzzy_like_pattern(query)

      name_like = name_like_node(like)
      desc_like = desc_like_node(like)

      scope.where(combined_search_node(name_like, desc_like, fuzzy))
           .order(search_ordering(name_like, desc_like, fuzzy), arel_table[:id].asc)
    end

    def like_pattern(query)
      "%#{sanitize_sql_like(query.to_s)}%".downcase
    end

    def name_like_node(like)
      lower(arel_table[:name]).matches(like)
    end

    def desc_like_node(like)
      lower(arel_table[:description]).matches(like)
    end

    def fuzzy_name_like_node(fuzzy)
      lower(arel_table[:name]).matches(fuzzy.downcase)
    end

    def combined_search_node(name_like, desc_like, fuzzy)
      combined = name_like.or(desc_like)
      combined = combined.or(fuzzy_name_like_node(fuzzy)) if fuzzy
      combined
    end

    def search_ordering(name_like, desc_like, fuzzy)
      ordering = Arel::Nodes::Case.new
      ordering.when(name_like).then(0)
      ordering.when(fuzzy_name_like_node(fuzzy)).then(1) if fuzzy
      ordering.when(desc_like).then(2)
      ordering.else(3)
      ordering
    end

    def fuzzy_like_pattern(query)
      str = query.to_s.strip
      return nil if str.length < 4
      return nil unless str.match?(/\A[[:alnum:]]+\z/)

      "%#{sanitize_sql_like(str.downcase).chars.join('%')}%"
    end

    def suggest_scope(scope, pattern)
      if postgresql_search?
        scope.where("name ILIKE ?", pattern)
      else
        scope.where("LOWER(name) LIKE LOWER(?)", pattern)
      end
    end

    def postgresql_search?
      connection.adapter_name.casecmp?("PostgreSQL")
    rescue StandardError
      false
    end
  end
end
