FactoryGirl.define do
  factory :ci_stage, class: Ci::LegacyStage do
    skip_create

    transient do
      name 'test'
      status nil
      warnings nil
      pipeline factory: :ci_empty_pipeline
    end

    initialize_with do
      Ci::LegacyStage.new(pipeline, name: name,
                                    status: status,
                                    warnings: warnings)
    end
  end

  factory :ci_stage_entity, class: Ci::Stage do
    project factory: :empty_project
    pipeline factory: :ci_empty_pipeline
    status 'pending'
  end
end
