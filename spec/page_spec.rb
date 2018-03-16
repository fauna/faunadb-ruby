RSpec.describe Fauna::Page do
  before(:all) do
    create_test_db
    @test_class = client.query { create ref('classes'), name: 'page_test' }[:ref]
    @foreach_class = client.query { create ref('classes'), name: 'page_foreach' }[:ref]

    index_refs = client.query { create ref('indexes'), name: 'page_refs', source: @test_class }
    index_values = client.query { create ref('indexes'), name: 'page_values', source: @test_class, values: [{ field: %w(data value) }] }
    index_foreach = client.query { create ref('indexes'), name: 'page_apply', source: @foreach_class }

    wait_for_index(index_refs[:ref], index_values[:ref], index_foreach[:ref])

    @refs_index = index_refs[:ref]
    @values_index = index_values[:ref]
    @foreach_index = index_foreach[:ref]

    @instances = client.query { (1..6).collect { |x| create(@test_class, data: { value: x }) } }.sort_by { |inst| inst[:ref].id }
    @instance_refs = @instances.collect { |instance| instance[:ref] }
    @instance_values = @instances.collect { |instance| instance[:data][:value] }.sort

    @refs_match = Fauna::Query.match(@refs_index)
    @values_match = Fauna::Query.match(@values_index)
    @foreach_match = Fauna::Query.match(@foreach_index)
  end

  after(:all) do
    destroy_test_db
  end

  describe '#==' do
    it 'equals identical page' do
      page1 = Fauna::Page.new(client, @refs_match, size: 1)
      page2 = Fauna::Page.new(client, @refs_match, size: 1)

      expect(page1).to eq(page2)
    end

    it 'does not equal different page' do
      page1 = Fauna::Page.new(client, @refs_match, size: 1234)
      page2 = Fauna::Page.new(client, @refs_match, size: 4321)

      expect(page1).not_to eq(page2)
    end
  end

  it 'can\'t mutate params directly' do
    page = client.paginate(@refs_match)

    expect { page.params[:ts] = random_number }.to raise_error(RuntimeError, 'can\'t modify frozen Hash')

    page = page.with_params(ts: random_number)

    expect { page.params[:ts] = random_number }.to raise_error(RuntimeError, 'can\'t modify frozen Hash')
  end

  describe 'builders' do
    def get_funcs(page)
      page.instance_variable_get(:@fauna_funcs)
    end

    def get_postprocessing(page)
      page.instance_variable_get(:@postprocessing_map)
    end

    describe '#with_params' do
      let(:ref1) { random_ref_string }
      let(:ref2) { random_ref_string }

      it 'sets params on copy' do
        ts1 = random_number
        ts2 = random_number

        page = client.paginate(@refs_match, ts: ts1)

        expect(page.with_params(ts: ts2, sources: false).params).to eq(ts: ts2, sources: false)
        expect(page.params).to eq(ts: ts1)
      end

      it 'reverses cursor' do
        page = client.paginate(@refs_match, before: ref1)

        expect(page.with_params(after: ref2).params).to eq(after: ref2)
        expect(page.params).to eq(before: ref1)
      end

      it 'preserves nil' do
        page = client.paginate(@refs_match, after: nil)

        expect(page.with_params(before: nil).params).to eq(before: nil)
        expect(page.params).to eq(after: nil)
      end

      it 'resets paging' do
        page = client.paginate(@refs_match, size: 1)
        page1 = page.page_after

        page2 = page1.with_params(after: 0).page_after

        expect(page2.data).to eq(page2.data)
      end
    end

    describe '#map' do
      it 'sets map on copy' do
        page = client.paginate(@refs_match)

        expect(get_funcs(page.map { |ref| get ref }).length).to be(1)
        expect(get_funcs(page).length).to be(0)
      end

      it 'performs map when paging' do
        page = client.paginate(@refs_match).map { |ref| get ref }

        expect(page.all).to eq(@instances)
      end
    end

    describe '#filter' do
      it 'sets filter on copy' do
        page = client.paginate(@values_match)

        expect(get_funcs(page.filter { |value| equals(modulo(value, 2), 0) }).length).to be(1)
        expect(get_funcs(page).length).to be(0)
      end

      it 'performs filter when paging' do
        page = client.paginate(@values_match).filter { |value| equals(modulo(value, 2), 0) }

        expect(page.all).to eq(@instance_values.find_all(&:even?))
      end
    end

    describe '#postprocessing_map' do
      it 'sets ruby map on copy' do
        page = client.paginate(@refs_match)

        expect(get_postprocessing(page.postprocessing_map(&:id))).to be_a(Proc)
        expect(get_postprocessing(page)).to be_nil
      end
    end
  end

  describe '#load!' do
    it 'explicitly loads page' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs[1])
      expected = [@instance_refs[1]]

      expect(page.instance_variable_get(:@data)).to be_nil
      page.load!
      expect(page.instance_variable_get(:@data)).to eq(expected)
    end

    it 'returns true when page was loaded' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs[1])

      expect(page.instance_variable_get(:@populated)).to be(false)
      expect(page.load!).to be(true)
      expect(page.instance_variable_get(:@populated)).to be(true)
    end

    it 'returns false when page not loaded' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs[1])

      page.load!
      expect(page.instance_variable_get(:@populated)).to be(true)
      expect(page.load!).to be(false)
    end
  end

  describe '#data' do
    it 'lazily loads page' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs[1])
      expected = [@instance_refs[1]]

      expect(page.instance_variable_get(:@data)).to be_nil
      expect(page.data).to eq(expected)
      expect(page.instance_variable_get(:@data)).to eq(expected)
    end
  end

  describe '#before' do
    it 'lazily loads page' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs[1])
      expected = [@instance_refs[1]]

      expect(page.instance_variable_get(:@before)).to be_nil
      expect(page.before).to eq(expected)
      expect(page.instance_variable_get(:@before)).to eq(expected)
    end
  end

  describe '#after' do
    it 'lazily loads page' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs[1])
      expected = [@instance_refs[2]]

      expect(page.instance_variable_get(:@after)).to be_nil
      expect(page.after).to eq(expected)
      expect(page.instance_variable_get(:@after)).to eq(expected)
    end
  end

  describe '#page_after' do
    it 'returns the page after' do
      page = client.paginate(@refs_match, size: 1, after: 0)

      @instance_refs.drop(1).each do |ref|
        page = page.page_after
        expect(page.data.first).to eq(ref)
      end
    end

    it 'returns nil on last page' do
      page = client.paginate(@refs_match, size: 1, after: @instance_refs.last)

      expect(page.data.first).to eq(@instance_refs.last)
      expect(page.page_after).to be_nil
    end

    it 'is not affected by lazy loading' do
      page = client.paginate(@refs_match, size: 1, after: 0)

      expect(page.data.first).to eq(@instance_refs[0])
      expect(page.page_after.data.first).to eq(@instance_refs[1])

      page = client.paginate(@refs_match, size: 1, after: 0)

      expect(page.page_after.data.first).to eq(@instance_refs[1])
    end
  end

  describe '#page_before' do
    it 'returns the page before' do
      page = client.paginate(@refs_match, size: 1, before: nil)

      @instance_refs.reverse.drop(1).each do |ref|
        page = page.page_before
        expect(page.data.first).to eq(ref)
      end
    end

    it 'returns nil on last page' do
      page = client.paginate(@refs_match, size: 1, before: @instance_refs.first)

      expect(page.page_before).to be_nil
    end

    it 'is not affected by lazy loading' do
      page = client.paginate(@refs_match, size: 1, before: nil)

      expect(page.data.first).to eq(@instance_refs[-1])
      expect(page.page_before.data.first).to eq(@instance_refs[-2])

      page = client.paginate(@refs_match, size: 1, before: nil)

      expect(page.page_before.data.first).to eq(@instance_refs[-2])
    end
  end

  it 'pages both directions' do
    page = client.paginate(@refs_match, size: 1, after: 0)
    expect(page.data.first).to eq(@instance_refs[0])

    page = page.page_after
    expect(page.data.first).to eq(@instance_refs[1])

    page = page.page_before
    expect(page.data.first).to eq(@instance_refs[0])
  end

  describe '#each' do
    it 'iterates the set in the after direction' do
      page = client.paginate(@refs_match, size: 1)
      refs = @instance_refs.collect { |ref| [ref] }

      expect(page.each.collect { |ref| ref }).to eq(refs)
    end

    it 'is not affected by lazy loading' do
      page = client.paginate(@refs_match, size: 1)
      refs = @instance_refs.collect { |ref| [ref] }

      expect(page.each.collect { |ref| ref }).to eq(refs)

      page = client.paginate(@refs_match, size: 1)
      refs = @instance_refs.collect { |ref| [ref] }

      expect(page.data).to eq([@instance_refs.first])
      expect(page.each.collect { |ref| ref }).to eq(refs)
    end

    context 'with fauna map' do
      it 'iterates the set using the fauna map' do
        page = client.paginate(@refs_match, size: 1) { |ref| get(ref) }
        instances = @instances.collect { |inst| [inst] }

        expect(page.each.collect { |inst| inst }).to eq(instances)
      end

      it 'chains multiple collection functions' do
        page = client.paginate(@refs_match, size: 1)
        # Map ref to value
        page = page.map { |ref| select(['data', 'value'], get(ref)) }
        # Filter out odd numbers
        page = page.filter { |value| equals(modulo(value, 2), 0) }
        # Map to double the value
        page = page.map { |value| multiply(value, 2) }

        # We are using the index on refs, not value, so we need to expect the values to be sorted by instance ref
        expected = @instances.collect { |inst| inst[:data][:value] }.find_all(&:even?).collect { |v| v * 2 }

        expect(page.all).to eq(expected)
      end
    end

    context 'with ruby map' do
      it 'iterates the set using the ruby map' do
        page = client.paginate(@refs_match, size: 1).postprocessing_map(&:id)
        ids = @instance_refs.collect { |ref| [ref.id] }

        expect(page.each.collect { |id| id }).to eq(ids)
      end
    end
  end

  describe '#reverse_each' do
    it 'iterates the set in the before direction' do
      page = client.paginate(@refs_match, size: 1, before: nil)
      refs = @instance_refs.reverse.collect { |ref| [ref] }

      expect(page.reverse_each.collect { |ref| ref }).to eq(refs)
    end
  end

  describe '#all' do
    it 'returns full contents of the set' do
      page = client.paginate(@refs_match, size: 1)

      expect(page.all).to eq(@instance_refs)
    end
  end

  describe '#foreach!' do
    before(:each) do
      @apply_refs = client.query { (1..3).collect { |x| select([:ref], create(@foreach_class, data: { value: x })) } }
    end

    it 'applies foreach to set' do
      # Sanity
      expect(client.query { map(@apply_refs) { |ref| exists ref } }).to eq(@apply_refs.collect { true })

      client.paginate(@foreach_match, size: 1).foreach! { |ref| delete ref }

      expect(client.query { map(@apply_refs) { |ref| exists ref } }).to eq(@apply_refs.collect { false })
    end
  end
end
