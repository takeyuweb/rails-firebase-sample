class MyAppSchema < GraphQL::Schema
  use GraphQL::Analysis::AST

  mutation(Types::MutationType)
  query(Types::QueryType)

  # Opt in to the new runtime (default in future graphql-ruby versions)
  use GraphQL::Execution::Interpreter

  # Add built-in connections for pagination
  use GraphQL::Pagination::Connections
end
