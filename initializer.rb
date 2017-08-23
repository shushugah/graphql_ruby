if ENV['GITHUB_TOKEN'].nil?
  puts 'GITHUB_TOKEN must be set. Create one here: https://github.com/settings/tokens'
  exit
end

require 'graphql/client'
require 'graphql/client/http'
require 'open-uri'

HTTPAdapter = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
  def headers(_context)
    { 'Authorization' => "Bearer #{ENV['GITHUB_TOKEN']}" }
  end
end

Client = GraphQL::Client.new(
  schema: 'schema.json',
  execute: HTTPAdapter
)

variables = {
  login: 'angular',
  repo: 'angular'
}

CommentQuery = Client.parse <<-'QUERY'
  query($login: String!, $repo: String!) {
    organization(login: $login) {
      repository(name: $repo) {
        name
        pullRequests(last: 100) {
          edges {
            node {
              title
              author{
               ...user_profile
              }
              reviews(last: 20){
                edges{
                  node {
                    author {
                      ...user_profile
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  fragment user_profile on User {
    name
    avatarUrl
  }
QUERY

result = Client.query(CommentQuery, variables: variables)
repository = result.data.organization.repository
open_pull_requests = repository.pull_requests.edges.map(&:node)
titles = open_pull_requests.map(&:title)
pr_authors = open_pull_requests.map { |node| node.data['author']['name'] }
# TODO: cleanup this variable
reviewers =
  open_pull_requests.map(&:reviews).map do |review|
    review.edges.map(&:data)
    end.flatten.map do |n|
    n['node']['author']['name']
  end

contributers = (pr_authors + reviewers).uniq.compact - ['']

puts ["The #{participants.count} contributers for #{variables[:repo]} are:"] + contributers
