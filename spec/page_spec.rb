RSpec.describe Fauna::Page do
  before(:all) do
    create_test_db
    @test_class = client.query { create ref('classes'), name: 'page_test' }[:ref]

    index_all = client.query { create ref('indexes'), name: 'page_all', source: @test_class }

    wait_for_active(index_all[:ref])

    @test_index = index_all[:ref]

    @instances = client.query { (1..3).collect { |x| create(@test_class, data: { value: x }) } }
    @instance_refs = @instances.collect { |instance| instance[:ref] }

    @test_match = Fauna::Query.match(@test_index)
  end

  after(:all) do
    destroy_test_db
  end

  it 'can\'t mutate params directly' do
    page = client.paginate(@test_match)

    expect { page.params[:ts] = random_number }.to raise_error(RuntimeError, 'can\'t modify frozen Hash')

    page = page.with_params(ts: random_number)

    expect { page.params[:ts] = random_number }.to raise_error(RuntimeError, 'can\'t modify frozen Hash')
  end

  describe 'builders' do
    describe '#with_params' do
      let(:ref1) { random_ref }
      let(:ref2) { random_ref }

      it 'sets params on copy' do
        ts1 = random_number
        ts2 = random_number

        page = client.paginate(@test_match, ts: ts1)

        expect(page.with_params(ts: ts2, sources: false).params).to eq(ts: ts2, sources: false)
        expect(page.params).to eq(ts: ts1)
      end

      it 'reverses cursor' do
        page = client.paginate(@test_match, before: ref1)

        expect(page.with_params(after: ref2).params).to eq(after: ref2)
        expect(page.params).to eq(before: ref1)
      end

      it 'preserves nil' do
        page = client.paginate(@test_match, after: nil)

        expect(page.with_params(before: nil).params).to eq(before: nil)
        expect(page.params).to eq(after: nil)
      end

      it 'resets paging' do
        page = client.paginate(@test_match, size: 1)
        page1 = page.page_after

        page2 = page1.with_params(after: 0).page_after

        expect(page2.data).to eq(page2.data)
      end
    end

    describe '#with_map' do
      it 'sets fauna map on copy' do
        page = client.paginate(@test_match)

        expect(page.with_map { |page_q| map(page_q) { |ref| get ref } }.fauna_map).not_to eq(page.fauna_map)
      end
    end

    describe '#with_ruby_map' do
      it 'sets ruby map on copy' do
        page = client.paginate(@test_match)

        expect(page.with_ruby_map(&:id).ruby_map).not_to eq(page.ruby_map)
      end
    end
  end

  describe '#next' do
    it 'returns next page' do
      page = client.paginate(@test_match, size: 1, after: 0)

      @instance_refs.each do |ref|
        page = page.page_after
        expect(page.data.first).to eq(ref)
      end
    end

    it 'returns nil on last page' do
      page = client.paginate(@test_match, size: 1, after: @instance_refs.last).page_after

      expect(page.page_after).to be_nil
    end
  end

  describe '#prev' do
    it 'returns prev page' do
      page = client.paginate(@test_match, size: 1, before: nil)

      @instance_refs.reverse_each do |ref|
        page = page.page_before
        expect(page.data.first).to eq(ref)
      end
    end

    it 'returns nil on last page' do
      page = client.paginate(@test_match, size: 1, before: @instance_refs.first).page_before

      expect(page.page_before).to be_nil
    end
  end

  context 'without cursor' do
    it 'next and prev returns the same page' do
      page = client.paginate(@test_match, size: 1)

      next_page = page.page_after
      expect(next_page).not_to be_nil

      prev_page = page.page_before
      expect(prev_page).to eq(next_page)
    end
  end

  it 'pages both directions' do
    page = client.paginate(@test_match, size: 1, after: 0).page_after
    expect(page.data.first).to eq(@instance_refs[0])

    page = page.page_after
    expect(page.data.first).to eq(@instance_refs[1])

    page = page.page_before
    expect(page.data.first).to eq(@instance_refs[0])
  end

  describe '#each' do
    it 'iterates the set in the after direction' do
      page = client.paginate(@test_match, size: 1)
      refs = @instance_refs.collect { |ref| [ref] }

      expect(page.each.collect { |ref| ref }).to eq(refs)
    end

    context 'with fauna map' do
      it 'iterates the set using the fauna map' do
        page = client.paginate(@test_match, size: 1) { |page_q| map(page_q) { |ref| get(ref) } }
        instances = @instances.collect { |inst| [inst] }

        expect(page.each.collect { |inst| inst }).to eq(instances)
      end
    end

    context 'with ruby map' do
      it 'iterates the set using the ruby map' do
        page = client.paginate(@test_match, size: 1).with_ruby_map(&:id)
        ids = @instance_refs.collect { |ref| [ref.id] }

        expect(page.each.collect { |id| id }).to eq(ids)
      end
    end
  end

  describe '#reverse_each' do
    it 'iterates the set in the before direction' do
      page = client.paginate(@test_match, size: 1, before: nil)
      refs = @instance_refs.reverse.collect { |ref| [ref] }

      expect(page.reverse_each.collect { |ref| ref }).to eq(refs)
    end
  end
end
