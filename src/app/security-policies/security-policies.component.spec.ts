import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SecurityPoliciesComponent } from './security-policies.component';

describe('SecurityPoliciesComponent', () => {
  let component: SecurityPoliciesComponent;
  let fixture: ComponentFixture<SecurityPoliciesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ SecurityPoliciesComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(SecurityPoliciesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
