RSpec.shared_examples 'a mutation that returns the error' do |error:|
  it do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(graphql_errors.first['message']).to eq(error)
  end
end
